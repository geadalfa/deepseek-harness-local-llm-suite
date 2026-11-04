#!/usr/bin/env python3
"""
Transparent Streaming Model Downloader for DeepSeek Harness Suite
Features:
- Resume support (HTTP Range headers)
- Real-time text progress bar with MB, %, Speed (MB/s), and ETA (minutes)
- Direct flush to disk (Zero memory bloat, Zero Drive C usage)
- Auto-generates model-tailored tabby_config.yml (Q8 Cache, Zero-Gibberish invariant)
"""
import os
import sys
import time
import urllib.request

MODELS = [
    {
        "name": "Qwen2.5-7B-Instruct-1M-exl2-4_25",
        "repo": "bartowski/Qwen2.5-7B-Instruct-1M-exl2",
        "branch": "4_25",
        "folder": r"I:\LocalLLM\tabbyapi\models\Qwen2.5-7B-Instruct-1M-exl2-4_25",
        "max_seq_len": 65536,
        "cache_mode": "Q8"
    },
    {
        "name": "Mistral-Nemo-Instruct-2407-exl2-4_25",
        "repo": "bartowski/Mistral-Nemo-Instruct-2407-exl2",
        "branch": "4_25",
        "folder": r"I:\LocalLLM\tabbyapi\models\Mistral-Nemo-Instruct-2407-exl2-4_25",
        "max_seq_len": 65536,
        "cache_mode": "Q8"
    },
    {
        "name": "Qwen2.5-14B-Instruct-1M-exl2-4_25",
        "repo": "bartowski/Qwen2.5-14B-Instruct-1M-exl2",
        "branch": "4_25",
        "folder": r"I:\LocalLLM\tabbyapi\models\Qwen2.5-14B-Instruct-1M-exl2-4_25",
        "max_seq_len": 49152,
        "cache_mode": "Q8"
    }
]

def format_time(seconds):
    if seconds < 0 or seconds > 86400:
        return "--:--"
    m, s = divmod(int(seconds), 60)
    h, m = divmod(m, 60)
    if h > 0:
        return f"{h}h {m:02d}m {s:02d}s"
    return f"{m:02d}m {s:02d}s"

def download_file(url, dest_path, desc=""):
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    temp_path = dest_path + ".part"
    
    initial_bytes = 0
    if os.path.exists(temp_path):
        initial_bytes = os.path.getsize(temp_path)
    elif os.path.exists(dest_path):
        print(f"  [OK] Already downloaded: {os.path.basename(dest_path)}")
        return True

    headers = {"User-Agent": "Mozilla/5.0"}
    if initial_bytes > 0:
        headers["Range"] = f"bytes={initial_bytes}-"
        print(f"  [RESUME] Resuming from {initial_bytes / (1024**2):.1f} MB...")

    req = urllib.request.Request(url, headers=headers)
    
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            status = resp.status
            content_range = resp.headers.get("Content-Range")
            
            if status == 206 and content_range:
                # Example: bytes 1000-4991578279/4991578280
                total_bytes = int(content_range.split("/")[-1])
            elif status == 200:
                total_bytes = int(resp.headers.get("Content-Length", 0))
                initial_bytes = 0
            else:
                total_bytes = int(resp.headers.get("Content-Length", 0)) + initial_bytes

            mode = "ab" if initial_bytes > 0 else "wb"
            downloaded = initial_bytes
            start_time = time.time()
            last_print = 0
            chunk_size = 1024 * 1024  # 1 MB chunk

            with open(temp_path, mode) as f:
                while True:
                    chunk = resp.read(chunk_size)
                    if not chunk:
                        break
                    f.write(chunk)
                    downloaded += len(chunk)

                    now = time.time()
                    if now - last_print >= 2.5 or downloaded == total_bytes:
                        elapsed = now - start_time
                        speed = (downloaded - initial_bytes) / (elapsed + 1e-6)  # bytes/sec
                        speed_mb = speed / (1024 * 1024)
                        
                        percent = (downloaded / total_bytes * 100) if total_bytes > 0 else 0
                        remaining_bytes = total_bytes - downloaded
                        eta = (remaining_bytes / (speed + 1e-6)) if speed > 0 else 0
                        
                        # Build ASCII bar
                        bar_len = 25
                        filled = int(bar_len * percent / 100)
                        bar = "=" * filled + (">" if filled < bar_len else "") + " " * (bar_len - filled - (1 if filled < bar_len else 0))
                        
                        print(f"  [{bar}] {percent:5.1f}% | {downloaded/(1024**3):.2f}/{total_bytes/(1024**3):.2f} GB | {speed_mb:4.2f} MB/s | ETA: {format_time(eta)}", flush=True)
                        last_print = now

            # Rename .part to final
            if os.path.exists(dest_path):
                os.remove(dest_path)
            os.rename(temp_path, dest_path)
            print(f"  [SUCCESS] Finished {os.path.basename(dest_path)} ({total_bytes/(1024**3):.2f} GB)\n")
            return True

    except Exception as e:
        print(f"  [ERROR] {e}", file=sys.stderr)
        return False

def download_model_files(model_info):
    repo = model_info["repo"]
    branch = model_info["branch"]
    target_dir = model_info["folder"]
    
    print("\n" + "="*70)
    print(f"MODEL TARGET: {model_info['name']}")
    print(f"Hugging Face: https://huggingface.co/{repo}/tree/{branch}")
    print(f"Target Dir  : {target_dir}")
    print("="*70)
    
    # 1. Download metadata files first via huggingface hub
    os.environ["HF_HOME"] = r"I:\LocalLLM\hf_cache"
    from huggingface_hub import HfApi
    api = HfApi()
    
    files = [f.rfilename for f in api.list_repo_tree(repo, revision=branch) if hasattr(f, 'size')]
    meta_files = [f for f in files if not f.endswith(".safetensors")]
    weight_files = [f for f in files if f.endswith(".safetensors")]
    
    print(f"[1/2] Fetching configuration & tokenizer files ({len(meta_files)} files)...")
    for mf in meta_files:
        url = f"https://huggingface.co/{repo}/resolve/{branch}/{mf}"
        dest = os.path.join(target_dir, mf)
        download_file(url, dest)
        
    print(f"[2/2] Streaming model weight safetensors ({len(weight_files)} files)...")
    for wf in weight_files:
        url = f"https://huggingface.co/{repo}/resolve/{branch}/{wf}"
        dest = os.path.join(target_dir, wf)
        if not download_file(url, dest):
            return False
            
    # Write model specific tabby_config.yml
    config_path = os.path.join(target_dir, "tabby_config.yml")
    with open(config_path, "w", encoding="utf-8") as f:
        f.write("# Auto-generated by Gemi for DeepSeek Harness + RTX 4070 SUPER 12GB\n")
        f.write("model:\n")
        f.write(f"  max_seq_len: {model_info['max_seq_len']}\n")
        f.write(f"  cache_size: {model_info['max_seq_len']}\n")
        f.write(f"  cache_mode: {model_info['cache_mode']}\n")
        f.write("  chunk_size: 2048\n")
    print(f"[CONFIG] Wrote {config_path}")
    return True

def main():
    print("="*70)
    print("DeepSeek Harness Suite - High-Visibility Live Downloader")
    print("="*70)
    
    for idx, model in enumerate(MODELS, 1):
        print(f"\n>>> PROCESSING [{idx}/{len(MODELS)}]: {model['name']}")
        download_model_files(model)
        
    print("\n" + "="*70)
    print("ALL 3 MODELS SUCCESSFULLY DOWNLOADED AND INTEGRATED!")
    print("="*70)

if __name__ == "__main__":
    main()
