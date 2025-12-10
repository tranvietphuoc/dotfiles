# Tài liệu hướng dẫn cài đặt ssh key cho github và gitlab

````markdown
# Hướng dẫn Cấu hình SSH Đa Tài khoản (GitHub & GitLab)

Tài liệu hướng dẫn chi tiết cách thiết lập SSH Key để sử dụng song song tài khoản **GitHub** (Cá nhân) và **GitLab** (Công việc) trên cùng một máy tính Linux (Fedora/Ubuntu/CentOS).

**Mục tiêu:**

- Khắc phục lỗi `Permission denied (publickey)`.
- Không cần nhập mật khẩu mỗi khi `git push`.
- Máy tính tự động nhận diện đúng tài khoản cho từng dịch vụ.

---

## 1. Chuẩn bị môi trường

Mở Terminal và truy cập vào thư mục cấu hình SSH.

```bash
mkdir -p ~/.ssh
cd ~/.ssh
```
````

---

## 2\. Tạo SSH Key riêng biệt

Tạo 2 cặp khóa riêng biệt để tránh xung đột.

### 2.1. Tạo Key cho GitHub (Cá nhân)

Thay `email_canhan@gmail.com` bằng email tài khoản GitHub của bạn.
_(Nhấn Enter khi được hỏi passphrase để bỏ qua)_.

```bash
ssh-keygen -t ed25519 -C "email_canhan@gmail.com" -f id_ed25519_github
```

### 2.2. Tạo Key cho GitLab (Công việc)

Thay `email_congviec@company.com` bằng email tài khoản GitLab của bạn.

```bash
ssh-keygen -t ed25519 -C "email_congviec@company.com" -f id_ed25519_gitlab
```

---

## 3\. Tạo file cấu hình (SSH Config)

Bước quan trọng nhất để định tuyến key nào dùng cho server nào.

1.  Tạo file config:

    ```bash
    nano ~/.ssh/config
    ```

2.  Dán toàn bộ nội dung sau vào file:

    ```text
    # --- Tài khoản GitHub (Cá nhân) ---
    Host github.com
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519_github
      IdentitiesOnly yes

    # --- Tài khoản GitLab (Công việc) ---
    Host gitlab.com
      HostName gitlab.com
      User git
      IdentityFile ~/.ssh/id_ed25519_gitlab
      IdentitiesOnly yes
    ```

3.  Lưu và thoát: Nhấn `Ctrl + O` -\> `Enter` -\> `Ctrl + X`.

---

## 4\. Phân quyền và Kích hoạt SSH Agent

Đảm bảo key được bảo mật và nạp vào bộ nhớ đệm.

```bash
# 1. Đặt quyền bảo mật (Fix lỗi 'UNPROTECTED PRIVATE KEY FILE')
chmod 600 ~/.ssh/id_ed25519_github
chmod 600 ~/.ssh/id_ed25519_gitlab

# 2. Khởi chạy SSH Agent
eval "$(ssh-agent -s)"

# 3. Thêm key vào Agent
ssh-add ~/.ssh/id_ed25519_github
ssh-add ~/.ssh/id_ed25519_gitlab
```

---

## 5\. Cập nhật Key lên Server

Copy nội dung file `.pub` và dán vào phần cài đặt SSH của GitHub/GitLab.

### 5.1. Với GitHub

1.  Copy nội dung key:
    ```bash
    cat ~/.ssh/id_ed25519_github.pub
    ```
2.  Truy cập: [GitHub SSH Settings](https://github.com/settings/keys).
3.  Nhấn **New SSH key** -\> Dán Key vào -\> **Add SSH key**.

### 5.2. Với GitLab

1.  Copy nội dung key:
    ```bash
    cat ~/.ssh/id_ed25519_gitlab.pub
    ```
2.  Truy cập: [GitLab SSH Keys](https://gitlab.com/-/profile/keys).
3.  Nhấn **Add new key** -\> Dán Key vào -\> **Add key**.

---

## 6\. Kiểm tra kết nối

Chạy lệnh test kết nối (không cần `sudo`).

```bash
# Test GitHub
ssh -T git@github.com
# Mong đợi: "Hi username! You've successfully authenticated..."

# Test GitLab
ssh -T git@gitlab.com
# Mong đợi: "Welcome to GitLab, @username!"
```

---

## 7\. Xử lý các Repository cũ (Chuyển HTTPS sang SSH)

Nếu bạn đã clone dự án bằng HTTPS trước đó, bạn cần chuyển sang SSH để không bị hỏi mật khẩu.

1.  Vào thư mục dự án, kiểm tra link hiện tại:

    ```bash
    git remote -v
    ```

2.  Nếu link bắt đầu bằng `https://...`, chạy lệnh đổi sang SSH:
    - **GitHub:**
      ```bash
      git remote set-url origin git@github.com:username-cua-ban/ten-repo.git
      ```
    - **GitLab:**
      ```bash
      git remote set-url origin git@gitlab.com:username-cua-ban/ten-repo.git
      ```

3.  Push thử:

    ```bash
    git push -u origin main
    ```

<!-- end list -->

```

```
