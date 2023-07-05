# Graylog v5.0

- Description
    - Graylog v5.0
    - MongoDB v5.0
    - OpenSeacrh v2.4.0


- Running

    `docker-compose -f docker-compose.yml up -d`


### Web Admin
- Default (.env)
    - Username : admin
    - Password : Kekasi.Co.ID 

if you want to change the password. can use the following command :

`echo -n yourpassword | shasum -a 256`

for the Linux operating system or Windows Subsystem for Linux (WSL)

change GRAYLOG_ROOT_PASSWORD_SHA2 in .env file
```
GRAYLOG_ROOT_PASSWORD_SHA2="d2f79ffcc92402afcfb1e1044a03e03dbedeae232c6dc4de53e842f887035e8a"
```
