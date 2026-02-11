# OpenELIS-Global-2 Development Environment Setup

These instructions show how to get your local development environment ready so you can build and run OpenELIS-Global-2.

Source: https://uwdigi.atlassian.net/wiki/spaces/oeg/pages/240844805/Dev%2BEnvironment%2BSetup%2BInstructions

## 1. Prepare your machine

### Update Ubuntu (example uses Ubuntu)

- [ ] Run system update:

```bash
sudo apt update
sudo apt upgrade
sudo apt full-upgrade
sudo apt autoremove
```

## 2. Install Java

- [ ] Install the default JDK:

```bash
sudo apt install default-jdk
java -version
javac -version
```

OpenELIS-Global requires Java to compile and run.

## 3. Install Docker and Docker Compose

### Install Docker

- [ ] Install Docker:

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
sudo systemctl status docker
```

### Allow Docker commands without sudo (optional)

- [ ] Add your user to the docker group:

```bash
sudo usermod -aG docker ${USER}
su - ${USER}
```

### Install Docker Compose

- [ ] Install Docker Compose:

```bash
sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

This lets you run the services in containers.

## 4. Install Chrome

- [ ] Download Chrome for your system and install it. This is useful for testing and accessing the running app.

## 5. Clone OpenELIS-Global-2

- [ ] Fork the repo:
   https://github.com/I-TECH-UW/OpenELIS-Global-2.git
- [ ] Change directory to your workspace:

```bash
cd /path/to/eclipse/workspace
```

- [ ] Clone the code:

```bash
git clone git@github.com:{Your_GitHub_Account}/OpenELIS-Global-2.git --recurse-submodules
```

Now you have the code locally.

## 6. Test deployment with Docker

- [ ] Go into the project folder:

```bash
cd OpenELIS-Global-2
```

- [ ] Start the containers:

```bash
docker-compose up -d
```

- [ ] Open in your browser:
   https://localhost:8443/OpenELIS-Global
   (You may need to accept a security warning.)

## 7. Optional: native dev setup (Tomcat + Eclipse)

If you want to work with the Java code directly, follow these steps.

### A. Install Maven

- [ ] Install Maven:

```bash
sudo apt install maven
mvn -version
```

Used to build the Java project.

### B. Install Eclipse

- [ ] Visit: https://www.eclipse.org/downloads/
- [ ] Download Eclipse (Java EE) and install it.

### C. Optional Eclipse plugins

- [ ] Install (if needed):
  - Jaspersoft Reports
  - eGit

These help with reporting and Git integration.

### D. Install Lombok in Eclipse

- [ ] Follow setup from the Lombok site:
https://projectlombok.org/setup/eclipse

### E. Import project in Eclipse

- [ ] File -> Import -> Projects from Folder or Archive
- [ ] Select OpenELIS-Global-2
- [ ] Also include dataexport-core and dataexport-api (sub-modules)

### F. Set up Tomcat server

- [ ] Download Tomcat (for example, version 9)
- [ ] Extract it somewhere (for example, your workspace)

In Eclipse:

- [ ] Go to Servers -> New -> Server
- [ ] Add Tomcat 9
- [ ] Point to your extracted Tomcat directory

### G. Configure Tomcat (optional SSL + properties)

- [ ] Add environment args like datasource credentials to Tomcat VM arguments.

- [ ] Map local properties:

```bash
sudo mkdir /run/secrets
sudo ln -s /path/to/project/dev/eclipse_common.properties /run/secrets/common.properties
```

- [ ] Make sure this contains the correct DB URLs and credentials for your local setup.

### H. Create log folder

- [ ] Create the log folder:

```bash
sudo mkdir /var/lib/openelis-global/logs/
sudo chmod 777 /var/lib/openelis-global/logs/
```

This gives Eclipse rights to write logs.

### I. Run the server in Eclipse

- [ ] Clean the project
- [ ] Start Tomcat (Run or Debug)

The app will open in your browser when running.

## Notes and tips

- You can choose Docker or Eclipse + Tomcat, or both. Docker is the quickest way to get running.
- With Docker you can hot-reload React front-end changes.
- If Eclipse build issues appear, use Project Clean -> Rebuild.
