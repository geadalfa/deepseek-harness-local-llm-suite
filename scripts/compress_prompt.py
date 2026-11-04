#!/usr/bin/env python3
"""
Microsoft LLMLingua / LongLLMLingua Token Compressor Utility
Part of: DeepSeek Harness Local LLM Suite
Compresses prompts by 50%-80% to fit within local model context windows while preserving semantic fidelity.
"""
import argparse
import sys
import os

def main():
    parser = argparse.ArgumentParser(description="Compress prompts using Microsoft LLMLingua-2")
    parser.add_argument("--file", "-f", help="Path to input text file to compress")
    parser.add_argument("--text", "-t", help="Raw text string to compress")
    parser.add_argument("--rate", "-r", type=float, default=0.5, help="Target compression rate (0.1 to 0.9, default 0.5)")
    parser.add_argument("--output", "-o", help="Optional output file path to write compressed text")
    args = parser.parse_args()

    content = ""
    if args.file:
        if not os.path.exists(args.file):
            print(f"[ERROR] File not found: {args.file}", file=sys.stderr)
            sys.exit(1)
        with open(args.file, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
    elif args.text:
        content = args.text
    else:
        parser.print_help()
        sys.exit(1)

    print(f"[INFO] Initial text length: {len(content)} characters (~{len(content)//4} estimated tokens)")
    print(f"[INFO] Initializing Microsoft LLMLingua-2 compressor (rate: {args.rate})...")

    try:
        from llmlingua import PromptCompressor
        compressor = PromptCompressor(
            model_name="microsoft/llmlingua-2-bert-base-multilingual-cased-meetingbank",
            use_llmlingua2=True
        )
        result = compressor.compress_prompt(
            content,
            rate=args.rate,
            use_bpe=True
        )
        compressed_text = result.get("compressed_prompt", "")
        origin_tokens = result.get("origin_tokens", len(content)//4)
        compressed_tokens = result.get("compressed_tokens", len(compressed_text)//4)
        ratio = result.get("ratio", f"{(compressed_tokens / max(origin_tokens, 1)):.2f}x")

        print(f"[SUCCESS] Compression complete!")
        print(f"   Original tokens  : {origin_tokens}")
        print(f"   Compressed tokens: {compressed_tokens} ({ratio} compression ratio)")
        print(f"   Tokens saved     : {origin_tokens - compressed_tokens} tokens")

        if args.output:
            with open(args.output, "w", encoding="utf-8") as out_f:
                out_f.write(compressed_text)
            print(f"[INFO] Compressed text written to: {args.output}")
        else:
            print("\n--- COMPRESSED PROMPT PREVIEW ---")
            print(compressed_text[:500] + ("..." if len(compressed_text) > 500 else ""))

    except ImportError:
        print("[ERROR] llmlingua is not installed. Run: pip install llmlingua", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"[ERROR] Compression failed: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
