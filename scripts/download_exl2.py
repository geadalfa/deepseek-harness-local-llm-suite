#!/usr/bin/env python3
"""
Hugging Face Resumable Model Downloader for TabbyAPI EXL2
Part of: DeepSeek Harness Local LLM Suite
"""
import argparse
import sys
import os

def download_model(repo_id: str, revision: str, local_dir: str):
    print(f"============================================================")
    print(f"Downloading Hugging Face Model: {repo_id}")
    print(f"Revision / Branch: {revision}")
    print(f"Target Directory : {local_dir}")
    print(f"============================================================")

    try:
        from huggingface_hub import snapshot_download
    except ImportError:
        print("[ERROR] huggingface_hub is not installed.")
        print("Please install it via: pip install huggingface_hub")
        sys.exit(1)

    os.makedirs(local_dir, exist_ok=True)

    try:
        downloaded_path = snapshot_download(
            repo_id=repo_id,
            revision=revision,
            local_dir=local_dir,
            local_dir_use_symlinks=False,
            resume_download=True,
            max_workers=4
        )
        print(f"\n[SUCCESS] Model successfully downloaded to: {downloaded_path}")
    except Exception as e:
        print(f"\n[ERROR] Failed to download model: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download EXL2 models with resume support")
    parser.add_argument("--repo", default="turboderp/Qwen2.5-Coder-7B-Instruct-exl2", help="Hugging Face repo ID")
    parser.add_argument("--revision", default="4.25bpw", help="Git revision or branch (e.g. 4.25bpw)")
    parser.add_argument("--out", required=True, help="Destination directory path")
    args = parser.parse_args()

    download_model(args.repo, args.revision, args.out)
