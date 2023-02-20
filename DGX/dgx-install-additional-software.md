# Install Additional Software

- Add the location where we install additional software to path
```
echo "export PATH=$PATH:$HOME/bin" >> ~/.bashrc
```

### AWS CLI

- Download the archive
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```
- Unzip the archive
```
unzip awscliv2.zip
```
- Install the aws-cli
```
./aws/install -i ~/aws-cli -b ~/bin
```
- Check version
```
aws --version
```

### Rclone

- Download the archive
```
wget https://downloads.rclone.org/rclone-current-linux-amd64.zip
```
- Unzip the archive
```
unzip rclone-current-linux-amd64.zip
```

- Copy the binary to `~/bin`
```
cp rclone-v1.61.1-linux-amd64/rclone ~/bin/rclone
```
- Check version
```
rclone --version
```
