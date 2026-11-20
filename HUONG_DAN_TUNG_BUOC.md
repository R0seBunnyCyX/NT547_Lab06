# LAB 06 – HƯỚNG DẪN TỪNG BƯỚC (Windows PowerShell)

> MSSV: **24520943** → contract sinh ra: **TipJar_0943**.
> Mọi lệnh chạy trong **PowerShell**, đứng tại thư mục `Lab06_SinhVien` (thư mục có `tools/`).
> Khung báo cáo: [report/MAU_BAO_CAO.md](report/MAU_BAO_CAO.md) — ảnh lưu vào `evidence/screenshots/` với **đúng tên** ghi ở mỗi bước (📸), báo cáo đã trỏ sẵn tới các tên đó.

## Quy tắc chụp ảnh (để thầy thấy được quá trình)

- Chụp **cả cửa sổ terminal**: thấy dòng lệnh đã gõ + kết quả ngay bên dưới. Không cắt riêng con số.
- Trước mỗi nhóm lệnh nên gõ `Clear-Host` để màn hình gọn, chỉ chứa bước đang chụp.
- Ảnh GitHub phải thấy **thanh địa chỉ (URL run)**, **commit SHA**, dấu ✗ đỏ / ✓ xanh.
- Không để lộ token, mật khẩu, private key trong ảnh.
- Phím tắt chụp: `Win + Shift + S` → dán vào Paint → lưu `.png` vào `evidence/screenshots/`.

## Thứ tự BẮT BUỘC

Cài đặt → tạo target → scan before → commit/push **CI RED** → sửa → scan after → commit/push **CI GREEN** → printers → mutation **CI RED** → revert **CI GREEN** → đóng gói.
**Không sửa `AuditTarget.sol` trước khi có CI RED đầu tiên.**

---

## BƯỚC 0 – Chuẩn bị GitHub

1. Xoá repo cũ (nếu còn): repo → **Settings** → cuối trang **Danger Zone** → **Delete this repository**.
2. Tạo repo mới **RỖNG**: **New repository** → tên `NT547_Lab06` → **KHÔNG** tick README / .gitignore / license → **Create**.
3. Copy URL HTTPS dạng `https://github.com/R0seBunnyCyX/NT547_Lab06.git`.

---

## BƯỚC 1 – Cài môi trường (mục 2 của PDF)

Mở PowerShell, di chuyển vào thư mục lab:

```powershell
cd "C:\Users\MSI VN\Desktop\Blockchain\Lab06\Lab06_SinhVien"
```

Tạo và kích hoạt môi trường ảo (Windows dùng `Activate.ps1`, **không** dùng `source`):

```powershell
python -m venv .venv
```

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
```

```powershell
.\.venv\Scripts\Activate.ps1
```

Đầu dòng lệnh sẽ hiện `(.venv)`. Cài Slither + solc-select:

```powershell
python -m pip install -r requirements.txt
```

Cài compiler 0.8.24 (**phải chạy sau khi đã activate .venv**):

```powershell
solc-select install 0.8.24
```

```powershell
solc-select use 0.8.24
```

Kiểm tra (đây là phần cần chụp):

```powershell
Clear-Host; solc --version; slither --version; dot -V; git --version; python tools/preflight.py
```

Kết quả đúng: `Version: 0.8.24+...`, `0.11.6`, `graphviz version ...`, preflight toàn `OK`.

📸 **`01_moi_truong.png`** – terminal có lệnh trên + toàn bộ kết quả.

> Lỗi thường gặp:
> - `solc` báo version khác 0.8.24 hoặc "not installed (set by SOLC_VERSION)" → chạy lại 2 lệnh `solc-select install/use 0.8.24` **trong khi đang có (.venv)**.
> - `dot` không tìm thấy → đóng PowerShell, mở cửa sổ mới (Graphviz đã cài, cần PATH mới), activate lại .venv. Nếu máy chưa có Graphviz: `winget install --id Graphviz.Graphviz -e`.
> - Mỗi lần mở PowerShell mới phải chạy lại: `cd ...`, `Set-ExecutionPolicy -Scope Process Bypass -Force`, `.\.venv\Scripts\Activate.ps1`.

---

## BƯỚC 2 – Tạo hợp đồng cá nhân (mục 3)

```powershell
Clear-Host; python tools/create_lab.py 24520943
```

```powershell
Get-Content lab_identity.json
```

Ghi lại **Session Code `SC-......`** vào báo cáo. **Không bao giờ** chạy lại lệnh này với `--force`.

📸 **`02_create_lab.png`** – lệnh tạo + nội dung `lab_identity.json` (MSSV, session_code, contract).

Mở `AuditTarget.sol` (VS Code hoặc Notepad) để đọc toàn bộ mã:

```powershell
code AuditTarget.sol
```

📸 **`03_source_baseline.png`** – mã nguồn baseline (thấy các hàm `changeOwner`, `plugin`, `redeemCode`, `sweep`, `noFunds`, `drip`). Có thể cần 2 ảnh.

---

## BƯỚC 3 – Nhiệm vụ 1: Scan BEFORE (mục 4)

```powershell
Clear-Host; python tools/scan.py --mode raw --tag before; Get-Content evidence\before_raw\summary.json
```

📸 **`04_scan_before_raw.png`**

```powershell
Clear-Host; python tools/scan.py --mode configured --tag before; Get-Content evidence\before_configured\summary.json
```

📸 **`05_scan_before_configured.png`**

Xem bảng finding:

```powershell
Clear-Host; Import-Csv evidence\before_raw\findings.csv | Format-Table index,check,impact,confidence,lines -AutoSize
```

📸 **`06_findings_before.png`**

Kết quả dự kiến (để bạn đối chiếu, **ghi số thật từ máy bạn**):

| Mode | High | Medium | Low | Informational |
|---|---|---|---|---|
| raw | 2 | 3 | 2 | 5 |
| configured | 2 | 3 | 0 | 0 |

Các detector dự kiến: `controlled-delegatecall` (High, `plugin`), `encode-packed-collision` (High, `redeemCode`), `incorrect-equality` (Medium, `noFunds`), `tx-origin` (Medium, `changeOwner`), `unchecked-lowlevel` (Medium, `sweep`), `missing-zero-check`, `timestamp` (Low), `low-level-calls`, `naming-convention` (Info).

So sánh raw ↔ configured: config chỉ bỏ Low/Informational (`exclude_low`, `exclude_informational`) và `solc-version`; **High/Medium giữ nguyên**.

---

## BƯỚC 4 – Nhiệm vụ 4.1: Commit baseline & CI RED (mục 7.1)

```powershell
Clear-Host; git init -b main; git add .; git commit -m "lab06: vulnerable baseline"
```

```powershell
git remote add origin https://github.com/R0seBunnyCyX/NT547_Lab06.git
```

```powershell
git push -u origin main
```

```powershell
git log --oneline -n 3; git rev-parse HEAD; git remote -v
```

📸 **`07_push_baseline.png`** – thấy commit, push thành công, SHA đầy đủ.

Trên GitHub: repo → tab **Actions** → workflow **Lab06 Slither gate** → run mới nhất (chờ 1–2 phút).

📸 **`08_ci_red_baseline.png`** – trang run có ✗ đỏ, URL trên thanh địa chỉ, SHA commit.
📸 **`09_ci_red_baseline_log.png`** – bấm job **audit** → mở step **Slither Solidity 0.8.24 (High + Medium gate)** → cuộn tới các dòng detector (`controlled-delegatecall`, `tx-origin`…).

Ghi lại: **Run URL #1** và **SHA #1**.

> RED chỉ hợp lệ khi log cho thấy Slither tìm ra finding Medium/High. Nếu đỏ vì `solc not found`, lỗi mạng… thì không tính — bấm **Re-run jobs**.

---

## BƯỚC 5 – Nhiệm vụ 2: Triage & sửa (mục 5)

Mở `AuditTarget.sol` và sửa **6 chỗ** dưới đây (4 lỗi thật + 2 đoạn ngữ cảnh).

### 5.1. `changeOwner` – tx-origin → **TP, sửa**

Chỉ đổi dòng kiểm tra quyền (giữ dòng `require` trong thân hàm — quan trọng cho bước mutation) và thêm event:

```solidity
    function changeOwner(address newOwner) external {
        require(msg.sender == owner, "not owner");
        require(newOwner != address(0), "zero");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }
```

Và thêm khai báo event ngay dưới dòng `event Deposited(...)`:

```solidity
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
```

### 5.2. `plugin` – controlled-delegatecall → **TP, sửa + phần còn lại accepted**

Baseline: **ai cũng gọi được**, tự chọn `target` → delegatecall chạy code lạ trong storage của contract → ghi đè `owner`, rút sạch ETH. Sửa: chỉ owner gọi, đích là module do owner cấu hình (không còn `target` do người gọi truyền vào).

Thêm biến state ngay dưới `mapping(bytes32 => bool) public redeemed;`:

```solidity
    address public module;
```

Thay toàn bộ hàm `plugin` bằng:

```solidity
    function setModule(address newModule) external onlyOwner {
        require(newModule.code.length > 0, "not a contract");
        module = newModule;
    }

    function plugin(bytes calldata data) external onlyOwner {
        require(module != address(0), "no module");
        // Accepted: caller is msg.sender-checked owner and destination is the owner-configured
        // module (no caller-supplied target). Residual risk = trust in owner's module choice.
        // slither-disable-next-line controlled-delegatecall
        (bool ok, ) = module.delegatecall(data);
        require(ok, "delegatecall failed");
    }
```

> Lý do còn suppression: Slither vẫn coi `module` là "input-controlled" vì nó được ghi từ tham số của `setModule`. Nhưng hàm ghi đó đã có `onlyOwner` (msg.sender) → rủi ro còn lại chỉ là tin tưởng owner. Suppression đặt **đúng 1 dòng, đúng 1 detector**.

### 5.3. `redeemCode` – encode-packed-collision → **TP, sửa**

`abi.encodePacked("ab","c")` == `abi.encodePacked("a","bc")` → mã đã dùng của chiến dịch này chặn/được dùng lại ở chiến dịch khác. Sửa đúng 1 chữ:

```solidity
        bytes32 id = keccak256(abi.encode(campaign, code));
```

### 5.4. `sweep` – unchecked-lowlevel → **TP, sửa**

```solidity
    function sweep(address payable to) external onlyOwner {
        require(to != address(0), "zero");
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "sweep failed");
    }
```

### 5.5. `noFunds` – incorrect-equality (Medium) → **Accepted (ngữ cảnh)**

Hàm `view`, chỉ trả dữ liệu hiển thị, không dùng để cấp quyền/chuyển tiền; dù ai đó ép ETH vào (force-send) thì chỉ làm sai giá trị hiển thị. Thêm 2 dòng comment ngay trên `return`:

```solidity
    function noFunds() external view returns (bool) {
        // Accepted: view-only UI helper, never used for access control or fund flow.
        // slither-disable-next-line incorrect-equality
        return address(this).balance == 0;
    }
```

### 5.6. `drip` – timestamp (Low) → **Accepted, không sửa code**

Hàm `onlyOwner`, timestamp chỉ dùng cho khoá 1 ngày; validator lệch được vài giây, không đáng kể so với 1 ngày, và chỉ owner gọi. Ghi lý do trong báo cáo.

> Ngoài ra `missing-zero-check` (Low) của `plugin` sẽ tự biến mất vì không còn tham số `target`.

Lưu file, rồi xem diff:

```powershell
Clear-Host; git diff -- AuditTarget.sol
```

📸 **`10_git_diff.png`** (diff dài → chụp 2 ảnh `10_git_diff.png`, `10b_git_diff.png`; nhấn `Space` để cuộn, `q` để thoát).

---

## BƯỚC 6 – Scan AFTER (mục 5 ý 7)

```powershell
Clear-Host; python tools/scan.py --mode raw --tag after; Get-Content evidence\after_raw\summary.json
```

📸 **`11_scan_after_raw.png`**

```powershell
Clear-Host; python tools/scan.py --mode configured --tag after; Get-Content evidence\after_configured\summary.json
```

📸 **`12_scan_after_configured.png`**

Dự kiến: **configured = 0 finding**; raw = 0 High, 0 Medium, 1 Low (`timestamp`), 5 Informational (4 `low-level-calls` + 1 `naming-convention`).

> Nếu configured vẫn còn Medium/High → đừng push, kiểm tra lại đoạn sửa tương ứng (comment `slither-disable-next-line` phải nằm **ngay dòng trước** câu lệnh bị báo).

---

## BƯỚC 7 – Nhiệm vụ 4.2: Commit fix & CI GREEN (mục 7.2)

```powershell
Clear-Host; git add .; git commit -m "lab06: fix and triage findings"; git push; git log --oneline -n 3; git rev-parse HEAD
```

📸 **`13_push_fix.png`**

GitHub → Actions → run mới nhất.

📸 **`14_ci_green_fix.png`** – ✓ xanh, URL, SHA.
📸 **`15_ci_green_fix_log.png`** – log step Slither có dòng `0 result(s) found`.

Ghi lại: **Run URL #2** và **SHA #2**.

---

## BƯỚC 8 – Nhiệm vụ 3: Printers & inheritance graph (mục 6)

```powershell
Clear-Host; python tools/print_arch.py; Get-ChildItem evidence\architecture
```

📸 **`16_print_arch.png`**

```powershell
Clear-Host; Get-Content evidence\architecture\human_summary.txt
```

📸 **`17_human_summary.png`**

Mở ảnh đồ thị:

```powershell
start evidence\architecture\inheritance.png
```

Dùng Paint khoanh/ghi chú 3 node: **AccessManaged** = quản lý quyền (`onlyAdmin`), **BalanceLedger** = mapping số dư (`balances`, `_credit`), **StudentAsset** = contract được gọi từ bên ngoài (`mint`). Lưu thành:

📸 **`18_inheritance_marked.png`**

> Không có `inheritance.png`? Chạy: `dot -Tpng evidence/architecture/ArchitectureDemo.sol.dot -o evidence/architecture/inheritance.png`

Commit kết quả printers:

```powershell
git add .; git commit -m "lab06: architecture printers"; git push
```

---

## BƯỚC 9 – Nhiệm vụ 5: Mutation RED → revert GREEN (mục 8)

### ⚠️ Lưu ý quan trọng đã kiểm chứng

Detector `tx-origin` của **Slither 0.11.6 chỉ quét thân các function, KHÔNG quét modifier** (file `slither/detectors/statements/tx_origin.py` lặp `for f in contract.functions`). Nếu đổi dòng trong `modifier onlyOwner` như PDF ghi, CI sẽ **vẫn GREEN**. Vì vậy:

**9.1. (Minh chứng, không commit)** – chứng minh mutation trong modifier không bị phát hiện:

Trong `modifier onlyOwner()` đổi `require(msg.sender == owner, "not owner");` → `require(tx.origin == owner, "not owner");`, lưu, rồi:

```powershell
Clear-Host; git diff -- AuditTarget.sol; python tools/scan.py --mode configured --tag mutation_modifier
```

📸 **`19_mutation_modifier_not_detected.png`** – diff 1 dòng + `issues= 0`.

Hoàn tác thay đổi này (chưa commit nên dùng checkout):

```powershell
git checkout -- AuditTarget.sol; git status --short
```

**9.2. Mutation thật (commit + push)** – đổi **đúng một dòng** kiểm tra quyền trong `changeOwner`:

```solidity
// TRƯỚC:
        require(msg.sender == owner, "not owner");   // dòng đầu tiên trong changeOwner
// SAU:
        require(tx.origin == owner, "not owner");
```

Kiểm tra local trước khi push:

```powershell
Clear-Host; git diff -- AuditTarget.sol; python tools/scan.py --mode configured --tag mutation; Import-Csv evidence\mutation_configured\findings.csv | Format-Table check,impact,confidence,lines
```

📸 **`20_mutation_diff_scan.png`** – diff đúng 1 dòng + finding `tx-origin` Medium.

```powershell
Clear-Host; git add AuditTarget.sol; git commit -m "lab06: one-line mutation tx-origin"; git push; git rev-parse HEAD
```

> Chỉ `git add AuditTarget.sol` (không `git add .`) để commit mutation đúng 1 dòng; nếu không, `git revert` sẽ xoá luôn thư mục evidence mutation. Các thư mục `evidence/mutation*` sẽ được commit ở bước 10.

📸 **`21_push_mutation.png`**

GitHub → Actions → run mới nhất:

📸 **`22_ci_red_mutation.png`** – ✗ đỏ, URL, SHA.
📸 **`23_ci_red_mutation_log.png`** – log có `uses tx.origin for authorization`.

Ghi lại: **Run URL #3**, **SHA #3**, detector `tx-origin`.

**9.3. Revert mutation**

```powershell
Clear-Host; git log --oneline -n 4
```

Đảm bảo commit trên cùng (HEAD) là `lab06: one-line mutation tx-origin`, rồi:

```powershell
git revert --no-edit HEAD; git push; git log --oneline -n 5; git rev-parse HEAD
```

📸 **`24_revert_push.png`**

GitHub → Actions → run mới nhất:

📸 **`25_ci_green_revert.png`** – ✓ xanh, URL, SHA.

Ghi lại: **Run URL #4**, **SHA #4**.

> Nếu HEAD không phải commit mutation (vì bạn commit thêm gì đó sau): `git log --oneline` → copy SHA của commit mutation → `git revert --no-edit <SHA>`.

📸 **`26_actions_list.png`** – trang **Actions** tổng thấy cả chuỗi run ✗ ✓ ✗ ✓.

---

## BƯỚC 10 – Hoàn thiện báo cáo & đóng gói (mục 9)

1. Điền số liệu, URL, SHA vào [report/MAU_BAO_CAO.md](report/MAU_BAO_CAO.md) (tìm các chỗ `____`).
2. Kiểm tra mọi ảnh đã nằm trong `evidence/screenshots/` đúng tên.
3. Commit báo cáo + ảnh:

```powershell
git add .; git commit -m "lab06: report and screenshots"; git push
```

> Commit này chỉ đổi report/ảnh nên CI vẫn GREEN (branch main giữ trạng thái GREEN).

4. Đóng gói:

```powershell
Clear-Host; python tools/package_submission.py; Get-ChildItem submissions
```

📸 **`27_package.png`**

5. Xuất PDF báo cáo (nếu LMS yêu cầu): VS Code → cài extension **Markdown PDF** → mở `report/MAU_BAO_CAO.md` → `Ctrl+Shift+P` → *Markdown PDF: Export (pdf)*.

6. Nộp LMS: file `submissions/NT547_Lab06_24520943.zip` (+ PDF nếu cần), link repo, 4 run URL, 4 SHA theo thứ tự **RED → GREEN → RED → GREEN**.

---

## Bảng ghi nhanh (điền trong lúc làm)

| # | Phase | SHA | Run URL | Kết quả |
|---|---|---|---|---|
| 1 | Baseline | | | RED |
| 2 | Fix | | | GREEN |
| 3 | Mutation | | | RED |
| 4 | Revert | | | GREEN |

Session code: `SC-FD5CB7`
