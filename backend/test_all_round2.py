import subprocess
import sys

def run():
    tests = [
        "backend/test_bike_flow.py",
        "backend/test_safety_flow.py",
        "backend/test_uploads.py"
    ]
    
    python_exe = sys.executable
    print(f"Running complete CampusLift verification suite with {python_exe}...\n")
    
    for t in tests:
        print(f"==================================================")
        print(f"Running: {t}")
        print(f"==================================================")
        result = subprocess.run([python_exe, t], capture_output=True, text=True)
        print(result.stdout)
        if result.stderr:
            print(f"STDERR:\n{result.stderr}")
        if result.returncode != 0:
            print(f"[FAILED] {t} returned code {result.returncode}")
            sys.exit(1)
            
    print("\n==================================================")
    print("ALL TEST SUITES (BIKE, SAFETY, UPLOADS) PASSED 100%!")
    print("==================================================")

if __name__ == "__main__":
    run()
