{ config, pkgs, lib, ... }:

# llama.cpp router for pi. In pi: /llama loads a model, /model selects it.
let
  port = 8080;
  baseUrl = "http://127.0.0.1:${toString port}";

  # Sized on unit: its 20 GiB of VRAM holds the weights, the 1 GiB image
  # projector, this context, and headroom for other GPU work. Every host uses
  # the same number so a model behaves the same everywhere.
  contextTokens = 61440;

  # Pinned to a commit so a re-upload can't change the file under the hash.
  fromHuggingFace = { repo, rev, file, sha256 }: pkgs.fetchurl {
    url = "https://huggingface.co/${repo}/resolve/${rev}/${file}";
    inherit sha256;
  };

  # The router names each model after its directory and loads an mmproj file
  # beside the weights for image input.
  models = let
    qwen = file: sha256: fromHuggingFace {
      repo = "unsloth/Qwen3.8-27B-GGUF";
      rev = "4ca720788d1e01f1bff70c033e0d0028fd02e502";
      inherit file sha256;
    };
  in pkgs.linkFarm "llm-models" {
    "Qwen3.8-27B/Qwen3.8-27B-UD-IQ4_XS.gguf" =
      qwen "Qwen3.8-27B-UD-IQ4_XS.gguf" "40fac4050e940397dbf13087afd50f4734a11805bf9d65ef8ddd7483470e6199";
    "Qwen3.8-27B/mmproj-F16.gguf" =
      qwen "mmproj-F16.gguf" "cbb841a9ee0636b2ec172f5bb8df2ea8dfeb01e90fe7c6126581d662a0b4e43e";
  };

  # Vulkan decodes ~38% faster than ROCm at long context on RDNA 3.
  llamaCpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  # Passing -m would start single-model mode instead of the router.
  # Without a sleep timeout a loaded model holds memory until explicitly
  # unloaded; sleeping models wake on the next request.
  # effort defaults to xhigh, which truncates before answering; low gains nothing.
  # Hybrid-attention models need the checkpoint flags to rewind a cached prompt.
  llmServe = pkgs.writeShellApplication {
    name = "llm-serve";
    text = ''
      exec ${config.llm.vulkanWrapper} ${llamaCpp}/bin/llama-server \
        --models-dir ${models} \
        --host 127.0.0.1 --port ${toString port} \
        --device Vulkan0 \
        -ngl 99 --jinja -fa on \
        --cache-type-k q8_0 --cache-type-v q8_0 \
        --cache-ram 4096 \
        --ctx-checkpoints 32 --checkpoint-min-step 0 \
        --sleep-idle-seconds 120 \
        -c ${toString contextTokens} -np 1 \
        --temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0 \
        --chat-template-kwargs '{"reasoning_effort":"medium"}' \
        "$@"
    '';
  };

  # pi reads the server URL from inside the stored credential, not the
  # environment. Merged, to leave other providers' credentials alone.
  seedPiAuth = pkgs.writeShellApplication {
    name = "seed-pi-auth";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      auth="$HOME/.pi/agent/auth.json"
      mkdir -p "$(dirname "$auth")"
      existing=$(jq . "$auth" 2>/dev/null || echo '{}')
      jq --arg url "${baseUrl}" \
        '.["llama.cpp"] = {type: "api_key", key: "local", env: {LLAMA_BASE_URL: $url}}' \
        <<<"$existing" > "$auth.tmp"
      chmod 600 "$auth.tmp"
      mv "$auth.tmp" "$auth"
    '';
  };
in
{
  options.llm.vulkanWrapper = lib.mkOption {
    type = lib.types.str;
    default = "";
    description = "Command prefix that gives llama-server a Vulkan driver outside NixOS.";
  };

  config = {
    home.packages = [ llamaCpp llmServe pkgs.pi-coding-agent ];

    home.sessionVariables = {
      LLAMA_BASE_URL = baseUrl;
      LLAMA_API_KEY = "local";
    };

    home.activation.seedPiAuth = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe seedPiAuth}
    '';

    # The router idles at ~1 GiB (nothing loaded until pi's /llama picks a
    # model), so leaving it up costs little and pi never has to be told where
    # to connect.
    systemd.user.services.llama-router = {
      Unit.Description = "llama.cpp router for local coding models";
      Service = {
        ExecStart = lib.getExe llmServe;
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
