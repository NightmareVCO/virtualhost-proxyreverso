#!/usr/bin/env bash
echo "Instalando estructura basica para clase virtualhost y proxy reverso"

# Habilitando la memoria de intercambio.
sudo dd if=/dev/zero of=/swapfile count=2048 bs=1MiB
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Instando los software necesarios para probar el concepto.
sudo apt update && sudo apt -y install zip unzip nmap apache2 certbot tree

# Instalando la versión sdkman y java
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Utilizando la versión de java 17 como base.
sdk install java 17.0.9-tem

# Subiendo el servicio de Apache.
sudo service apache2 start

# Clonando el repositorio.
git clone https://github.com/NightmareVCO/virtualhost-proxyreverso.git

# Copiando los archivos de configuración en la ruta indicada.
sudo cp ~/virtualhost-proxyreverso/configuraciones/virtualhost.conf /etc/apache2/sites-available/
sudo cp ~/virtualhost-proxyreverso/configuraciones/seguro.conf /etc/apache2/sites-available/
sudo cp ~/virtualhost-proxyreverso/configuraciones/proxyreverso.conf /etc/apache2/sites-available/

# Ingresando los nombres de los servidores de manera dinamica
cd /etc/apache2/sites-available/
read -p "Ingrese el nombre del host #1: " server_name1
read -p "Ingrese el nombre del host #2: " server_name2
read -p "Ingrese su correo: " correo

# Cambiando el virtualhost
sudo sed -i "s/ServerName CAMBIAR1/ServerName $server_name1/g" virtualhost.conf
sudo sed -i "s/ServerName CAMBIAR2/ServerName $server_name2/g" virtualhost.conf

# Cambiando el proxyreverso
sudo sed -i "s/ServerName CAMBIAR/ServerName $server_name1/g" proxyreverso.conf

# Cambiando el seguro
sudo sed -i "s/ServerName CAMBIAR/$server_name1/g" seguro.conf

# Actualizar redirección HTTP
sudo sed -i "s/Redirect 301 \/ https:\/\/CAMBIAR1\//Redirect 301 \/ https:\/\/$server_name1\//g" seguro.conf
# Actualizar el bloque de configuración de SSL
sudo sed -i "s/servername CAMBIAR1/servername $server_name1/g" seguro.conf
sudo sed -i "s/SSLCertificateFile \/etc\/letsencrypt\/live\/CAMBIAR1\/cert.pem/SSLCertificateFile \/etc\/letsencrypt\/live\/$server_name1\/cert.pem/g" seguro.conf
sudo sed -i "s/SSLCertificateKeyFile \/etc\/letsencrypt\/live\/CAMBIAR1\/privkey.pem/SSLCertificateKeyFile \/etc\/letsencrypt\/live\/$server_name1\/privkey.pem/g" seguro.conf
sudo sed -i "s/SSLCertificateChainFile \/etc\/letsencrypt\/live\/CAMBIAR1\/chain.pem/SSLCertificateChainFile \/etc\/letsencrypt\/live\/$server_name1\/chain.pem/g" seguro.conf

# Actualizar redirección HTTP
sudo sed -i "s/Redirect 301 \/ https:\/\/CAMBIAR2\//Redirect 301 \/ https:\/\/$server_name2\//g" seguro.conf
# Actualizar el bloque de configuración de SSL
sudo sed -i "s/servername CAMBIAR2/servername $server_name2/g" seguro.conf
sudo sed -i "s/SSLCertificateFile \/etc\/letsencrypt\/live\/CAMBIAR2\/cert.pem/SSLCertificateFile \/etc\/letsencrypt\/live\/$server_name2\/cert.pem/g" seguro.conf
sudo sed -i "s/SSLCertificateKeyFile \/etc\/letsencrypt\/live\/CAMBIAR2\/privkey.pem/SSLCertificateKeyFile \/etc\/letsencrypt\/live\/$server_name2\/privkey.pem/g" seguro.conf
sudo sed -i "s/SSLCertificateChainFile \/etc\/letsencrypt\/live\/CAMBIAR2\/chain.pem/SSLCertificateChainFile \/etc\/letsencrypt\/live\/$server_name2\/chain.pem/g" seguro.conf

# Configuracion de apache2
sudo a2enmod proxy proxy_html proxy_http ssl
sudo systemctl restart apache2
sudo service apache2 stop

echo "Debe aceptar cerbot"

# Configurando cerbot
sudo certbot certonly -m $correo -d $server_name1
sudo certbot certonly -m $correo -d $server_name2

# Creando las estructuras de los archivos.
sudo mkdir -p /var/www/html/app1 /var/www/html/app2

# Creando los archivos por defecto.
printf "<h1>Sitio Aplicacion #1</h1>" | sudo tee /var/www/html/app1/index.html
printf "<h1>Sitio Aplicacion #2</h1>" | sudo tee /var/www/html/app2/index.html

# Clonando el proyecto ORM y moviendo a la carpeta descargada.
cd ~/
git clone https://github.com/vacax/orm-jpa
cd orm-jpa

# Ejecutando la creación de fatjar
./gradlew shadowjar

# Subiendo la aplicación puerto por defecto.
java -jar ~/orm-jpa/build/libs/app.jar > ~/orm-jpa/build/libs/salida.txt 2> ~/orm-jpa/build/libs/error.txt &

# Clonando el proyecto #2 y moviendo a la carpeta descargada
cd ~/
git clone https://github.com/NightmareVCO/p4-publica.git
cd p4-publica

# Ejectuando la creacion de fatjar
./gradlew shawdojar

# Subiendo la apliacacion a puerto designado
java -jar ~/p4-publica/build/libs/app.jar > ~/p4-publica/build/libs/salida.txt 2> ~/p4-publica/build/libs/error.txt &


