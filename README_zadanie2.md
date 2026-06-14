# Zadanie 2 
# Kalina Salamończyk

---

## Plik pipeline

Plik znajduje się w `.github/workflows/docker.yml`.

Pipeline uruchamia się automatycznie przy każdym pushu na branch `main`.

### Kolejność kroków:

1. **Checkout** — pobranie kodu z repozytorium
2. **Setup QEMU** — konfiguracja emulatora do budowania na arm64
3. **Setup Buildx** — konfiguracja zaawansowanego buildera Dockera
4. **Login do DockerHub** — potrzebny do zapisu/odczytu cache
5. **Login do GHCR** — potrzebny do pushowania finalnego obrazu
6. **Build image for scanning** — budowanie obrazu lokalnie (tylko amd64) do skanowania
7. **Scan with Trivy** — skanowanie CVE, pipeline zatrzymuje się jeśli znajdzie CRITICAL lub HIGH
8. **Build and push** — budowanie na obie platformy i push do GHCR (tylko jeśli skan przeszedł)

---

## Konfiguracja sekretów

W Settings → Secrets and variables → Actions dodano dwa sekrety:

| Nazwa | Opis |
|-------|------|
| `DOCKERHUB_USERNAME` | login do DockerHub |
| `DOCKERHUB_TOKEN` | token wygenerowany w DockerHub → Account Settings → Security |

Dodatkowo w Settings → Actions → General ustawiłam **Read and write permissions**
dla workflow, co jest wymagane do pushowania obrazu do GHCR.

---

## Obsługiwane platformy

Obraz budowany jest na dwie architektury:
- `linux/amd64` — standardowe komputery i serwery x86_64
- `linux/arm64` — procesory ARM (np. Apple M1/M2, Raspberry Pi, serwery AWS Graviton)

Do obsługi multi-platform build użyto:
- `docker/setup-qemu-action` — emulacja architektury arm64 na maszynie GitHub Actions
- `docker/setup-buildx-action` — rozszerzony builder obsługujący wiele platform jednocześnie

---

## Tagowanie obrazów

Finalny obraz publikowany jest z tagiem `latest`:
ghcr.io/kalinasalamonczyk/weather-app:latest

Zdecydowałam się na tag `latest` ponieważ pipeline uruchamia się przy każdym
pushu na branch `main`, który zawsze zawiera aktualną i przetestowaną wersję
aplikacji. Zgodnie z dokumentacją Docker,
tag `latest` powinien wskazywać na najnowszą stabilną wersję obrazu
— co jest spełnione przy tym podejściu, bo każdy push na `main`
przechodzi przez skan CVE zanim obraz trafi do rejestru.

---

## Tagowanie cache

Cache przechowywany jest w dedykowanym publicznym repozytorium na DockerHub:
kalinasalamonczyk/weather-app-cache:cache

Użyto eksportera `registry` w trybie `mode=max`, który zapisuje cache
dla wszystkich warstw pośrednich (nie tylko końcowego obrazu).
Dzięki temu kolejne buildy są znacznie szybsze — warstwy z instalacją
zależności Pythona nie są pobierane i budowane od zera przy każdym uruchomieniu.

Pierwsze uruchomienie pipeline'u pokazało błąd `not found` przy pobieraniu cache
— jest to zachowanie oczekiwane, ponieważ cache nie istniał jeszcze w rejestrze.
Od drugiego uruchomienia cache jest poprawnie wykorzystywany.

---

## Skanowanie CVE — wybór narzędzia

Do skanowania podatności wybrałam **Trivy** (aquasecurity/trivy-action).

Powody wyboru Trivy zamiast Docker Scout:
- działa jako gotowa akcja GitHub bez dodatkowej konfiguracji
- nie wymaga osobnego tokenu ani logowania do zewnętrznego serwisu
- parametr `exit-code: 1` automatycznie przerywa pipeline gdy wykryje zagrożenia
- parametr `severity: CRITICAL,HIGH` precyzyjnie określa które zagrożenia blokują push
- parametr `ignore-unfixed: true` ignoruje podatności dla których nie ma jeszcze poprawki

Obraz trafia do GHCR tylko wtedy gdy krok skanowania zakończy się sukcesem
— jeśli Trivy wykryje CVE sklasyfikowane jako CRITICAL lub HIGH, pipeline
zatrzymuje się i push nie jest wykonywany.

---

## Potwierdzenie działania

Pipeline został uruchomiony i zakończył się sukcesem:

<img width="677" height="131" alt="image" src="https://github.com/user-attachments/assets/4eff25d0-37aa-454b-9f33-c7e99b887c8b" />


---

## Linki

- Obraz na GHCR: `ghcr.io/kalinasalamonczyk/weather-app:latest`
- Cache na DockerHub: `kalinasalamonczyk/weather-app-cache:cache`
- Repozytorium: `https://github.com/kalinasalamonczyk/zadanie1`
