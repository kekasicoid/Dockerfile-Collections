# PHP 8.4.27 — nginx + php-fpm + supervisor (Debian 13 / Trixie)

Image all-in-one PHP 8.4.27 yang menjalankan **nginx**, **php-fpm**, dan **supervisor**
dalam satu container, lengkap dengan agent **Elastic APM**. Image ini bersifat
generik (reusable) dan **tidak** membawa kode aplikasi — kode Anda di-mount/COPY
sendiri ke `/var/www/html`.

Base image: `php:8.4.27-fpm-trixie`.

## Isi image

| Komponen       | Keterangan                                                        |
| -------------- | ----------------------------------------------------------------- |
| PHP            | 8.4.27 (fpm), listen di `127.0.0.1:9000`                          |
| nginx          | seri `1.26.x` (di-pin via `ARG NGINX_VERSION`), listen port `80`  |
| supervisor     | PID 1, menjalankan `php-fpm` + `nginx`                            |
| Elastic APM    | agent PHP `1.17.1` (di-pin via `ARG ELASTIC_APM_VERSION`)         |

### Ekstensi PHP terpasang
`mysqli`, `pdo_mysql`, `soap`, `curl`, `zip`, `gd` (freetype + jpeg),
`mbstring`, `bcmath`, `pcntl`, `xml`.

### Konfigurasi PHP default (`zz-app.ini`)
| Direktif              | Nilai |
| --------------------- | ----- |
| `memory_limit`        | 512M  |
| `upload_max_filesize` | 64M   |
| `post_max_size`       | 64M   |
| `date.timezone`       | UTC   |
| `max_execution_time`  | 300   |
| `max_input_time`      | 300   |

## Build Arguments

| ARG                   | Default        | Keterangan                                                |
| --------------------- | -------------- | --------------------------------------------------------- |
| `NGINX_VERSION`       | `1.26.*`       | Pin versi nginx dari repo Debian Trixie.                  |
| `ELASTIC_APM_VERSION` | `1.17.1`       | Versi agent Elastic APM PHP (mendukung PHP 7.2–8.4).      |
| `PHP_API_VERSION`     | `20240924`     | PHP API version PHP 8.4, dipakai untuk nama file `.so` APM. |

## Build

```bash
docker build -f Dockerfile -t kekasi-php:8.4.27-trixie .
```

Build dengan override versi nginx (mis. pin ke revisi penuh):

```bash
docker build --build-arg NGINX_VERSION="1.26.3-3+deb13u9" \
  -f Dockerfile -t kekasi-php:8.4.27-trixie .
```

## Menjalankan

Mount kode aplikasi Anda ke webroot `/var/www/html`:

```bash
docker run --rm -p 8080:80 -v "$PWD":/var/www/html kekasi-php:8.4.27-trixie
```

Lalu buka http://localhost:8080.

> **Catatan mount:** image ini mem-bake `/var/www/html/index.php` berisi `phpinfo()`
> sebagai smoke test. Jika Anda me-mount folder kode ke `/var/www/html`, mount tersebut
> **menimpa** isi image, jadi `index.php` bawaan tidak akan terlihat. Jalankan tanpa
> mount untuk melihat halaman `phpinfo()`.

Cek versi nginx pada image yang sudah dibangun:

```bash
docker run --rm kekasi-php:8.4.27-trixie nginx -v
```

## Elastic APM

Agent APM sudah terpasang dan `elastic_apm.enabled=true`. Nilai spesifik seperti
`server_url` dan `service_name` **tidak** di-bake ke image — isi via environment
variable saat deploy, contoh:

```bash
docker run --rm -p 8080:80 \
  -e ELASTIC_APM_SERVER_URL="http://apm-server:8200" \
  -e ELASTIC_APM_SERVICE_NAME="my-php-app" \
  -v "$PWD":/var/www/html \
  kekasi-php:8.4.27-trixie
```

Pool php-fpm memakai `clear_env=no` agar environment variables (termasuk konfigurasi
APM) diteruskan ke worker.

## Arsitektur runtime

```
                 ┌─────────────── container ───────────────┐
  :80  ─────────▶│  nginx  ──fastcgi──▶ 127.0.0.1:9000 php-fpm │
                 │     └──────── supervisord (PID 1) ───────┘  │
                 └─────────────────────────────────────────────┘
                         root: /var/www/html
```

nginx memakai pola front-controller (`try_files $uri $uri/ /index.php?$query_string`),
cocok untuk framework seperti Laravel atau Symfony. Log nginx dan supervisor diarahkan
ke stdout/stderr sehingga tampil di `docker logs`.

## Catatan

- Pola satu-container multi-proses (nginx + php-fpm via supervisor) praktis untuk
  deployment sederhana. Untuk skala produksi, memisahkan nginx dan php-fpm ke dua
  container sering lebih disarankan.
- Versi nginx `1.26.*` mengikuti paket Debian 13 (Trixie). Pin pola minor dipilih
  agar build tetap mendapat patch keamanan tanpa gagal ketika revisi paket penuh
  ditarik dari repo.
