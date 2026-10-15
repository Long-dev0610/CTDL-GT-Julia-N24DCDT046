### A Pluto.jl notebook ###
# v1.0.4

using Markdown
using InteractiveUtils

# ╔═╡ 09102026-0000-4000-8000-000000000001
begin
    READ_DATA = true
    RUN_APP = true
    ROOT_DATA = joinpath(@__DIR__, "data")
end

# ╔═╡ 09102026-0000-4000-8000-000000000002
AppCore = let
    sandbox = Module(:ThucHanhNgay0910)
    Base.include(sandbox, joinpath(@__DIR__, "TH_2026_10_09_Sinh_vien.jl"))
    Base.invokelatest(getfield, sandbox, :GiaoDon)
end

# ╔═╡ 09102026-0000-4000-8000-000000000003

md"""
# BÁO CÁO THỰC HÀNH CẤU TRÚC DỮ LIỆU VÀ GIẢI THUẬT

**Họ và tên:** Lê Minh Long  
**Mã số sinh viên:** N24DCDT046  
**Ngôn ngữ lập trình:** Julia

---

## 1. Mục tiêu bài thực hành

Xây dựng ứng dụng mô phỏng quy trình điều phối giao hàng, từ đọc dữ liệu CSV, tìm kiếm và sắp xếp đơn hàng đến xác định đường đi, tối ưu phương án giao hàng và quản lý trạng thái thực hiện.

## 2. Các thuật toán sử dụng

**Merge Sort – Sắp xếp trộn**

Chia danh sách đơn hàng thành hai nửa, sắp xếp đệ quy rồi trộn lại theo tiêu chí cho trước. Thuật toán bảo đảm tính ổn định khi các phần tử có cùng mức ưu tiên.

Độ phức tạp thời gian: O(n log n).

**Binary Search – Tìm kiếm nhị phân**

Tìm đơn hàng theo ID trong danh sách đã được sắp xếp tăng dần. Mỗi lần so sánh loại bỏ khoảng một nửa không gian tìm kiếm.

Độ phức tạp thời gian: O(log n).

**BFS – Tìm kiếm theo chiều rộng**

Sử dụng hàng đợi vòng CircularQueue để tìm đường đi ít cạnh nhất từ kho đến các địa điểm giao hàng trên đồ thị không trọng số.

Độ phức tạp thời gian: O(V + E).

**Knapsack 0/1 – Quy hoạch động**

Lựa chọn tập đơn hàng có tổng lợi ích lớn nhất mà tổng chi phí thời gian không vượt quá ngân sách. Mỗi đơn hàng chỉ được chọn một lần.

Độ phức tạp thời gian: O(nB).

## 3. Dữ liệu thực hành

- MSSV dùng để sinh dữ liệu: N24DCDT046.
- Số đơn hàng: 8.
- Số cạnh của bản đồ: 7.
- Ngân sách thời gian: 30 đơn vị.
- Tệp đầu vào: don_hang.csv và ban_do.csv.

## 4. Kết quả thực hiện

| Chỉ tiêu | Kết quả |
|---|---|
| Tổng số đơn hàng | 8 |
| Số đơn được chọn | 6 |
| Đơn đã giao | 6, 8, 1, 3, 4, 5 |
| Đơn không chọn | 2, 7 |
| Tổng thời gian | 30/30 |
| Tổng lợi ích | 66 |
| Kiểm thử tự động | 60/60 đạt |

## 5. Nhận xét

Chương trình đã kết hợp các thuật toán sắp xếp, tìm kiếm, duyệt đồ thị và quy hoạch động để xây dựng quy trình điều phối giao hàng.

Với bộ dữ liệu N24DCDT046, chương trình lựa chọn sáu đơn hàng, sử dụng hết ngân sách thời gian và đạt tổng lợi ích 66. Kết quả được đối chiếu với tệp CSV đã xuất và bộ kiểm thử.
"""


# ╔═╡ 09102026-0000-4000-8000-000000000004
ho_so = AppCore.profile("N24DCDT046")

# ╔═╡ 09102026-0000-4000-8000-000000000005
du_lieu = READ_DATA ? AppCore.read_data(joinpath(ROOT_DATA,"N24DCDT046")) : nothing

# ╔═╡ 09102026-0000-4000-8000-000000000006
bao_cao = !RUN_APP || du_lieu === nothing ? nothing : let
    s = AppCore.build_session(du_lieu.orders,du_lieu.edges,ho_so)
    r = AppCore.plan!(s)
    trace = NamedTuple[]
    save(label) = push!(trace,(buoc=label,queue=AppCore.queue_values(s.pending),
                              stack=copy(s.completed),spent=s.spent,earned=s.earned))
    save("Sau lập kế hoạch")
    AppCore.deliver!(s); save("Sau giao một đơn")
    AppCore.undo!(s); save("Sau hoàn tác")
    while s.pending.count > 0
        AppCore.deliver!(s)
    end
    save("Sau giao hết")
    (chi_phi=copy(s.costs),tuyen=deepcopy(s.routes),chon=copy(s.selected_ids),
     loi_ich_toi_uu=r.optimal.value,truy_vet=trace,bat_bien=AppCore.check_invariants(s))
end

# ╔═╡ 09102026-0000-4000-8000-000000000007

md"""
# GIẢI THÍCH THUẬT TOÁN QUY HOẠCH ĐỘNG

## 1. Bài toán

Cho n đơn hàng, mỗi đơn hàng i có:

- Chi phí thời gian w_i.
- Lợi ích v_i.
- Ngân sách thời gian tối đa B.

Yêu cầu chọn tập đơn hàng sao cho tổng lợi ích lớn nhất và tổng thời gian không vượt quá B.

Mỗi đơn chỉ được chọn một lần.

## 2. Định nghĩa trạng thái

Gọi F(i,b) là lợi ích lớn nhất có thể đạt được khi xét i đơn hàng đầu tiên với ngân sách b.

Điều kiện ban đầu:

- F(0,b) = 0 với mọi b.
- F(i,0) = 0 khi mọi đơn hàng có chi phí dương.

## 3. Công thức truy hồi

Nếu chi phí đơn i lớn hơn ngân sách b:

F(i,b) = F(i-1,b)

Nếu chi phí đơn i không vượt ngân sách:

F(i,b) = max(F(i-1,b), F(i-1,b-w_i) + v_i)

Trong đó:

- F(i-1,b): Không chọn đơn thứ i.
- F(i-1,b-w_i) + v_i: Chọn đơn thứ i.

Khi hai phương án có cùng lợi ích, chương trình ưu tiên phương án không chọn đơn đang xét.

## 4. Cài đặt trong Julia

Vì Julia đánh chỉ số mảng bắt đầu từ 1, trạng thái F(i,b) được lưu tại:

`table[i+1,b+1]`

Chương trình tạo bảng DP gồm n+1 hàng và B+1 cột.

Sau khi tính bảng, thuật toán truy vết ngược để xác định danh sách ID được chọn.

## 5. Kết quả bộ dữ liệu cá nhân

**MSSV: N24DCDT046**

| Đơn ID | Chi phí | Lợi ích | Lựa chọn |
|---|---:|---:|---|
| 1 | 5 | 13 | Chọn |
| 2 | 9 | 5 | Không |
| 3 | 5 | 11 | Chọn |
| 4 | 7 | 12 | Chọn |
| 5 | 7 | 7 | Chọn |
| 6 | 3 | 13 | Chọn |
| 7 | 9 | 8 | Không |
| 8 | 3 | 10 | Chọn |

Tổng chi phí các đơn được chọn:

5 + 5 + 7 + 7 + 3 + 3 = 30

Tổng lợi ích:

13 + 11 + 12 + 7 + 13 + 10 = 66

Vậy phương án có tổng lợi ích tối ưu là **66**, với ngân sách **30**.

## 6. Đánh giá

Quy hoạch động giúp tìm phương án tối ưu đối với ngân sách nguyên không âm. Thuật toán có thời gian O(nB) và bộ nhớ O(nB) khi lưu toàn bộ bảng để truy vết.

Phương án được lựa chọn đã được xác nhận qua chương trình kiểm thử và kết quả CSV.
"""


# ╔═╡ 09102026-0000-4000-8000-000000000008

md"""
# MINH CHỨNG VÀ KẾT QUẢ THỰC HÀNH

**Sinh viên:** Lê Minh Long  
**MSSV:** N24DCDT046

## 1. Kết quả kiểm thử tự động

Lệnh kiểm thử sử dụng:

`julia TH_2026_10_09_Kiem_thu.jl --phase=all`

| Thành phần | Số kiểm thử đạt |
|---|---:|
| Kiểm tra dữ liệu | 12/12 |
| Merge Sort | 8/8 |
| Binary Search | 5/5 |
| BFS | 7/7 |
| Dynamic Programming | 12/12 |
| Tích hợp ứng dụng | 16/16 |
| **Tổng cộng** | **60/60** |

Tất cả 60 phép kiểm thử trong bộ kiểm thử được cung cấp đều đạt.

## 2. Quy trình thực nghiệm

**Bước 1: Tạo dữ liệu**

Chạy lệnh:

`julia TH_2026_10_09_Sinh_vien.jl --data N24DCDT046`

Kết quả tạo được 8 đơn hàng và 7 cạnh của đồ thị.

**Bước 2: Chạy chương trình**

Chạy lệnh:

`julia TH_2026_10_09_Sinh_vien.jl N24DCDT046 --menu`

Thực hiện lập kế hoạch và đưa những đơn đã chọn vào hàng đợi giao hàng.

**Bước 3: Giao hàng**

Các đơn được giao theo thứ tự:

6 → 8 → 1 → 3 → 4 → 5

Sau khi giao hết, hàng đợi rỗng.

**Bước 4: Xuất CSV**

Sử dụng chức năng số 6 trong menu để xuất tệp:

`data/N24DCDT046/ket_qua.csv`

## 3. Kết quả giao hàng

| Chỉ tiêu | Giá trị |
|---|---|
| Đơn được chọn | 1, 3, 4, 5, 6, 8 |
| Đơn không chọn | 2, 7 |
| Đơn đã giao | 6, 8, 1, 3, 4, 5 |
| Tổng thời gian | 30 |
| Tổng lợi ích | 66 |
| Ngân sách | 30 |
| Hàng đợi cuối | Rỗng |

## 4. Kiểm tra tính nhất quán

Chương trình duy trì các bất biến:

- Không có đơn hàng bị lặp trong tập được chọn.
- Mỗi đơn được chọn nằm trong hàng đợi hoặc ngăn xếp hoàn thành.
- Tổng thời gian đã dùng không vượt ngân sách.
- Tổng lợi ích thực nhận đúng bằng lợi ích của các đơn đã giao.

Trong lần chạy thực tế, trạng thái cuối có tổng thời gian 30, tổng lợi ích 66 và không còn đơn chờ giao.

## 5. Danh sách tệp minh chứng

- `TH_2026_10_09_Sinh_vien.jl`
- `TH_2026_10_09_Kiem_thu.jl`
- `TH_2026_10_09_Pluto.jl`
- `data/N24DCDT046/don_hang.csv`
- `data/N24DCDT046/ban_do.csv`
- `data/N24DCDT046/ket_qua.csv`
- `Phieu_thuc_hanh_CTDL_GT_2026_10_09.docx`

## 6. Kết luận

Bài thực hành đã triển khai và kiểm thử thành công bốn thuật toán chính bằng Julia.

Ứng dụng đã xử lý dữ liệu theo MSSV N24DCDT046, lựa chọn và giao sáu đơn hàng với tổng lợi ích 66 trong ngân sách 30.

Kết quả 60/60 phép kiểm thử là minh chứng cho việc chương trình đáp ứng bộ kiểm thử được cung cấp.

**GitHub repository:** Bổ sung sau khi tải bài lên.

**Commit SHA:** Bổ sung sau khi commit.
"""


# ╔═╡ 09102026-0000-4000-8000-000000000009
if RUN_APP && bao_cao !== nothing
    println("Kết quả từ cùng lõi ứng dụng Julia:")
    show(stdout, "text/plain", bao_cao)
    println()
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.7"
manifest_format = "2.0"
project_hash = "71853c6197a6a7f222db0f1978c7cb232b87c5ee"

[deps]
"""

# ╔═╡ Cell order:
# ╠═09102026-0000-4000-8000-000000000001
# ╠═09102026-0000-4000-8000-000000000002
# ╠═09102026-0000-4000-8000-000000000003
# ╠═09102026-0000-4000-8000-000000000004
# ╠═09102026-0000-4000-8000-000000000005
# ╠═09102026-0000-4000-8000-000000000006
# ╠═09102026-0000-4000-8000-000000000007
# ╠═09102026-0000-4000-8000-000000000008
# ╠═09102026-0000-4000-8000-000000000009
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
