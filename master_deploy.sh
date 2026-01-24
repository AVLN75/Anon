#!/bin/bash
# [ THIN-AIR : FINAL INTEGRATED ENGINEERING STACK ]

# 1. SETUP PROJECT DIRECTORIES
mkdir -p thinair/{bin,src,mnt,pdf_store}
cd thinair

echo "[*] Creating Steganographic Mounter..."
cat << 'PY' > bin/ghost_mount.py
import os, subprocess, sys

def find_payload(pdf_path):
    with open(pdf_path, "rb") as f:
        data = f.read()
        offset = data.rfind(b"%%EOF") + 5
        return offset

if __name__ == "__main__":
    offset = find_payload("src/document.pdf")
    # Launch Docker with HWID Spoofing and Loop Mount
    cmd = [
        "docker", "run", "--privileged", "-d",
        "--name", "thinair_core",
        "--hostname", "ENGINEERING-STATION-01",
        "-p", "8080:8080", "-p", "443:4500/udp",
        "-v", f"{os.getcwd()}:/host",
        "thinair_baked",
        "bash", "-c", f"tail -c +{offset+1} /host/src/document.pdf > /tmp/disk.vhd && \
        mount -o loop /tmp/disk.vhd /mnt/vhd && /start.sh"
    ]
    subprocess.run(cmd)
PY

echo "[*] Building AI Gateway & Bypass Logic..."
cat << 'GO' > src/gateway.go
package main
import (
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
)
func main() {
	// Bypass Redirects: Map license checks to local 'OK' responder
	http.HandleFunc("/auth/verify", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, `{"status":"success","license":"valid"}`)
	})
	
	// Services
	desktop, _ := url.Parse("http://127.0.0.1:6080")
	http.Handle("/desktop/", httputil.NewSingleHostReverseProxy(desktop))
	http.Handle("/storage/", http.FileServer(http.Dir("/mnt/vhd")))
	
	fmt.Println("Stealth Portal active on port 8080")
	http.ListenAndServe(":8080", nil)
}
GO

echo "[*] Baking the Docker Image (Kali + OpenWrt + AI)..."
cat << 'DOCKER' > Dockerfile
FROM kalilinux/kali-rolling
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    strongswan swanctl golang-go python3-pip \
    novnc x11vnc xvfb fluxbox curl iptables \
    iproute2 bridge-utils ffmpeg dnsmasq \
    && apt-get clean

# Portable AI Engine
RUN curl -L https://ollama.com/download/ollama-linux-amd64 -o /usr/bin/ollama && chmod +x /usr/bin/ollama

# Compile Gateway
COPY src/gateway.go /gateway.go
RUN go build -o /usr/local/bin/gateway /gateway.go

# Startup: VPN, DNS Spoofing, AI, UI
RUN echo "#!/bin/bash\n\
dnsmasq --address=/license.provider.com/127.0.0.1\n\
ollama serve & sleep 5 && ollama pull dolphin-llama3 &\n\
/usr/lib/ipsec/charon & gateway & \n\
Xvfb :1 -screen 0 1024x768x16 & DISPLAY=:1 fluxbox & x11vnc -display :1 -nopw -forever & \n\
/usr/share/novnc/utils/launch.sh --vnc localhost:5900 --listen 6080\n" > /start.sh
RUN chmod +x /start.sh
ENTRYPOINT ["/start.sh"]
DOCKER

# 2. COMPILE AND WRAP
docker build -t thinair_baked .

echo "--------------------------------------------------"
echo "[!] SYSTEM READY."
echo "1. Put your PDF and VHD in thinair/src/ and merge them."
echo "2. Run: python3 bin/ghost_mount.py"
echo "3. Access: http://localhost:8080"
