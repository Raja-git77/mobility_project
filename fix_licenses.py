import os
import subprocess

sdk_path = r"C:\Users\RAJAVEL\AppData\Local\Android\Sdk"
sdkmanager_path = os.path.join(sdk_path, "cmdline-tools", "latest", "bin", "sdkmanager.bat")

if not os.path.exists(sdkmanager_path):
    ct_dir = os.path.join(sdk_path, "cmdline-tools")
    if os.path.exists(ct_dir):
        for d in os.listdir(ct_dir):
            p = os.path.join(ct_dir, d, "bin", "sdkmanager.bat")
            if os.path.exists(p):
                sdkmanager_path = p
                break

print(f"Using sdkmanager at: {sdkmanager_path}")

if os.path.exists(sdkmanager_path):
    try:
        process = subprocess.Popen(
            [sdkmanager_path, "--licenses"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        inputs = "\n".join(["y"] * 50) + "\n"
        stdout, stderr = process.communicate(input=inputs, timeout=30)
        print("Licenses successfully accepted via SDK Manager!")
    except Exception as e:
        print(f"Error: {e}")
else:
    print("Error: sdkmanager.bat not found!")