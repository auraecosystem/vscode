sudo /Applications/Docker.app/Contents/MacOS/install --user testuser --proxy-http-mode="manual" --override-proxy-pac="http://localhost:8080/myproxy.pac"
sudo hdiutil attach Docker.dmg
sudo /Volumes/Docker/Docker.app/Contents/MacOS/install
sudo hdiutil detach /Volumes/Docker
npm i
bash scripts/code.sh
