# Quy Trình Release (Deplao Custom)

Tài liệu này hướng dẫn cách phát hành bản mới cho Deplao (phiên bản custom của bạn).

## Yêu cầu trước khi release

- Đã cài **GitHub CLI** (`gh`) và đăng nhập (`gh auth login`)
- Remote `myfork` đã trỏ về repo của bạn: `hoangkimboi/deplao`
- Đang ở đúng thư mục `deplao-builder`

## Cách phát hành bản mới (Khuyến nghị)

### 1. Sử dụng script tự động (Cách nhanh nhất)

```powershell
# Tăng patch (ví dụ: 26.4.3 → 26.4.4)
.\release.ps1 -Patch

# Tăng minor (ví dụ: 26.4.3 → 26.5.0)
.\release.ps1 -Minor

# Tăng major (ví dụ: 26.4.3 → 27.0.0)
.\release.ps1 -Major

# Hoặc chỉ định version trực tiếp
.\release.ps1 26.4.5
```

Script sẽ tự động:
- Cập nhật version trong `package.json`
- Commit thay đổi
- Build production
- Tạo tag và push
- Tạo GitHub Release + upload file

### 2. Quy trình thủ công (nếu cần)

1. Tăng version trong `package.json`
2. Commit thay đổi:
   ```bash
   git add package.json
   git commit -m "chore(release): bump version to vX.Y.Z"
   ```
3. Build:
   ```powershell
   npm run production
   ```
4. Tạo tag và push:
   ```bash
   git tag vX.Y.Z
   git push myfork vX.Y.Z
   ```
5. Tạo Release trên GitHub:
   - Vào https://github.com/hoangkimboi/deplao/releases
   - Nhấn "Draft a new release"
   - Chọn tag vừa tạo
   - Upload 3 file từ thư mục `dist-electron-build`:
     - `Deplao-Setup-X.Y.Z.exe`
     - `Deplao-Setup-X.Y.Z.exe.blockmap`
     - `latest.yml`
   - Nhấn **Publish release**

## Sau khi release

- Nhân viên sẽ nhận được thông báo cập nhật khi mở app (nếu đã cài bản có hỗ trợ Auto Update).
- Lần đầu tiên nhân viên **phải cài thủ công** bản mới nhất để bật tính năng Auto Update.
- Từ lần sau trở đi, cập nhật sẽ diễn ra tự động (hoặc có thông báo).

## Lưu ý quan trọng

- **Không push source code** lên repo công khai nếu không muốn lộ logic nội bộ.
- Luôn test kỹ bản build trên máy của bạn trước khi release.
- Nên ghi rõ trong Release Notes những thay đổi quan trọng (đặc biệt phần AI).

## Cấu trúc file liên quan

- `release.ps1` — Script tự động release
- `package.json` — Chứa version hiện tại
- `dist-electron-build/` — Thư mục chứa file build sau khi chạy production

---

Cập nhật lần cuối: 2026
