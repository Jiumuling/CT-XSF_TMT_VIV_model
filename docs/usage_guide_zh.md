# 使用指南

从下载压缩包到跑通自己的工况、选择想要的输出，一步一步说明。

---

## 1. 运行环境

* **MATLAB R2023a 或更新版本。** 核心算法以 P-code 发布，有版本锁：用 R2023a
  编译，只能在 R2023a 及更新版本运行，更旧的版本不行。
* **不需要任何工具箱**，求解器和全部后处理都只用基础 MATLAB。
* 整个包只有几 MB，示例算例在普通笔记本上一分钟内就能跑完。

## 2. 下载与解压

1. 打开 <https://github.com/Jiumuling/CT-XSF_TMT_VIV_model>
2. 点绿色 **Code** 按钮 → **Download ZIP**（也可用
   `git clone https://github.com/Jiumuling/CT-XSF_TMT_VIV_model.git`）
3. 解压到任意目录，例如 `D:\CT-XSF_TMT_VIV_model`
4. 在 MATLAB 里把“当前文件夹”切到该目录

解压后的结构：

```text
CT-XSF_TMT_VIV_model/
├── ctXsfSetup.m        路径设置（每次开 MATLAB 先运行它）
├── README.md           总说明
├── src/                【公开、可编辑】参数接口 + 后处理/出图/导出
├── lib/                【加密】52 个 .p，核心求解器
├── examples/           7 个可运行示例（最好的模板）
├── docs/               参数手册、模型说明、加密说明、复现指南、本指南
└── data/               可选参考数据（DNS 对比）放这里
```

一句话记住：**改 `src/`，不要去动 `lib/`**。`src/` 里全是普通 `.m` 文件，
改完存盘立即生效，不需要编译；`lib/*.p` 是核心算法，既改不了也用不着改。

## 3. 第一次运行（四行代码）

```matlab
ctXsfSetup;                          % 1. 把 lib/、src/、examples/ 加入路径
params = ctXsfDefaultParams();       % 2. 取得全部默认参数
result = ctXsfSolveVIV(params);      % 3. 调用加密核心求解器
ctXsfReport(result, params.output);  % 4. 按选择输出图与表
```

接着可以直接跑现成的示例，例如

```matlab
addpath('examples');
example_02_viv_shear_flow            % 线性剪切流的标准 VIV 算例
```

## 4. 哪些文件可以编辑

| 路径 | 作用 | 能否编辑 |
|---|---|---|
| `src/ctXsfDefaultParams.m` | **输入总入口**，所有参数的默认值都在这 | 可以 |
| 你自己的脚本（从 examples 复制） | 本次运行的参数与输出选择 | 可以 |
| `src/ctXsfReport*.m` | 各输出分组的图 | 可以 |
| `src/ctXsfStyleAxes.m` | 所有图统一的坐标轴字体/网格 | 可以 |
| `src/ctXsfReportExport.m` | 导出哪些表格、如何命名 | 可以 |
| `src/ctXsfFatigue*.m` | 雨流疲劳计算与表格 | 可以 |
| `lib/*.p` | 核心数值算法 | **不可以**（加密 P-code） |

推荐做法：把 `examples/example_02_viv_shear_flow.m` 复制成 `my_case.m` 再改，
示例保持原样当参考。若希望某个值**成为所有脚本的默认值**，就改
`src/ctXsfDefaultParams.m`。

## 5. 输入参数

所有输入都是 `ctXsfDefaultParams` 返回结构体的字段，完整的逐项手册见
[parameter_reference.md](parameter_reference.md)。最常用的如下：

| 组 | 含义 | 主要字段（单位） |
|---|---|---|
| **A 杆件** | 几何与材料 | `D` 外径(m)、`d` 内径(m，0=实心)、`L` 长度(m)、`section_type` `'solid'/'hollow'`、`rhos` 密度(kg/m³)、`E` 弹性模量(Pa)、`nu` 泊松比、`kappa` 剪切修正 |
| **B 液体** | 外部/内部流体 | `rho`、`rho_inner` (kg/m³)、`eta` 附加质量系数、`g` |
| **C 流速与流型** | 流速大小与剖面 | `flow_profile` `'uniform'/'linear_shear'/'custom'`、`U_top`(m/s)、`beta` 剪切强度、`flow_profile_z/U`（custom 用）、`St` |
| **D 边界** | 支承条件 | `boundary_preset`、`bcPreset.KthetaFactor`（以 EI/L 为单位）、`bcPreset.KuFactor`、`bcPreset.Ctheta/Cu`、手动 `bc.left/right.*` |
| **E 水动力与尾流** | 经验系数 | `CL0`（**设为 0 则只做模态分析**）、`CD0`、`C_D`、`Ax`、`Ay`、`epsilon_x/y` |
| **F 轴力** | 静力与动力部分 | `N_top`(N)、`include_submerged_weight`、`use_user_defined_w`+`w_user_defined`、`use_variable_tension`、`lambda_DeltaN` |
| **G 数值** | 网格、时间与窗口 | `Nz_total`、`dt`(s)、`T_total`(s)、`nt`、`rms_tail_fraction` 统计窗口比例、`tail_time_fraction` 时空窗口比例、`SaveStride` |
| **H 输出** | 目录与选择 | `output.out_dir`、`output.figure_dir`、`output.figures`、`output.save_fig`、`output.enable_export`、`output.make_plots`、`hotspot_region_fraction`、`case_id` |
| **I 参考数据** | 可选 DNS 对比 | `dns.enable`、`dns.file`、`dns.cols`、`dns.z_mode` |
| **J 模态** | 特征值分析 | `modal_n_modes`、`modal_environment` `'water'/'air'` |
| **K 疲劳** | 雨流筛查 | `fatigue.enable`、`fatigue.m_values`、`fatigue.n_phi`、`fatigue.regions_z_over_D_paper` |

边界预设名：`pinned_pinned`、`clamped_clamped`、`free_free`、`guided_guided`、
`semi_rigid_both`、`elastic_both`、`cantilever_left_clamped_right_free`、
`left_pinned_right_free`、`left_clamped_right_pinned`、`manual`。

## 6. 选择输出

```matlab
params.output.figures = {'displacement','internal_force','fatigue'};
```

| 分组 | 内容 |
|---|---|
| `'displacement'` | 位移包络、RMS 分布、时程、轨迹、频谱 |
| `'internal_force'` | 弯矩/剪力统计与包络、真值与位移假设对比 |
| `'fatigue'` | 应力包络与标准差、应力时空图、应力热点、雨流相对疲劳 |
| `'time_space'` | 位移时空热图 |
| `'wake'` | 尾流振子强度分布 |
| `'tension'` | 动态附加轴力与端部有效轴力历程 |
| `'modal'` | 固有频率 |
| `'all'` | 全部（默认） |

目录、导出与“只出一份干净结果”的写法：

```matlab
params.case_id           = 'myCase01';                        % 文件名前缀
params.output.out_dir    = fullfile(pwd,'my_results');        % 留空则自动建 CTXSF_outputs_时间戳
params.output.figure_dir = fullfile(params.output.out_dir,'figures');
params.output.save_fig   = true;    % 保存 PNG + FIG
params.output.enable_export = true; % 写 Excel / MAT
params.output.make_plots = true;    % false = 图不弹窗（批处理/服务器）

% 只要自己选的那几组，不要内置的整套报告文件：
params.output.save_fig = false; params.output.enable_export = false;
params.output.make_plots = false;
result = ctXsfSolveVIV(params);
ctXsfReport(result, params.output);
```

## 7. 结果文件

全部写在 `params.output.out_dir` 下，前缀是工况编号（case id）：

* `*_key_metrics.xlsx` —— 本次运行的关键指标
* `*_spanwise_profiles.xlsx` —— 沿跨长的位移、内力、应力剖面数据
* `*_fatigue_indicators.xlsx` —— 弯曲/剪应力的最大值与标准差
* `*_axial_tension_history.xlsx` —— 动态附加轴力与端部有效轴力历程
* `*_relative_fatigue_*.xlsx` —— 雨流相对需求剖面、分区汇总、热点、采样检查
* `*_internal_force_hotspots.xlsx`、`*_true_vs_assumed_MQ_hotspot_regions.xlsx` —— 分区热点表
* `figures/*.png` 与 `figures/*.fig` —— 每张选中的图（FIG 可在 MATLAB 里再编辑）
* `*_summary.mat` —— 完整 `result` 结构体；`*_tail_fields.mat` —— 保留末段时空场

## 8. 可直接复制的模板

```matlab
%% my_case.m —— 我自己的工况
clear; clc; close all;
ctXsfSetup;

params = ctXsfDefaultParams();

% ---- 杆件 ----
params.section_type = 'hollow';
params.D = 0.05; params.d = 0.04; params.L = 25.0;
params.rhos = 7850; params.E = 2.10e11; params.nu = 0.30;

% ---- 液体 ----
params.rho = 1025; params.rho_inner = 1025; params.eta = 1.0;

% ---- 流速与流型 ----
params.flow_profile   = 'custom';
params.flow_profile_z = [0; 0.5*params.L; params.L];   % z = 0 在顶端
params.flow_profile_U = [1.20; 0.85; 0.45];            % m/s

% ---- 边界 ----
params.boundary_preset = 'semi_rigid_both';
params.bcPreset.KthetaFactor = 15;

% ---- 轴力 ----
params.N_top = 1.0e5;
params.include_submerged_weight = true;   % false = 沿跨长恒定静张力
params.use_variable_tension     = true;   % false = 完全不计 DeltaN
params.lambda_DeltaN            = 1.0;    % 0 = 只计算不反馈

% ---- 网格 / 时间 / 后处理窗口 ----
params.Nz_total = 401; params.dt = 0.005; params.T_total = 5.0;
params.nt = ceil(params.T_total/params.dt);
params.rms_tail_fraction       = 0.30;    % 用最后 30% 数据做统计
params.tail_time_fraction      = 0.40;    % 末段时空窗口比例
params.hotspot_region_fraction = 0.10;    % 端部热点区 = 两端各 10% 跨长

% ---- 输出选择 ----
params.case_id        = 'myCase01';
params.output.out_dir = fullfile(pwd,'my_results');
params.output.figures = {'displacement','internal_force','fatigue'};
params.output.save_fig = true;

% ---- 计算与出图 ----
result = ctXsfSolveVIV(params);           % 加密核心
ctXsfReport(result, params.output);       % 公开后处理

fprintf('max y_rms/D = %.4f, max sigma_b = %.3e Pa, max DeltaN = %.1f N\n', ...
    max(result.rms_Y_dyn)/params.D, max(result.max_sigma_b), max(result.DeltaN));
```

只做模态分析：把 `params.CL0` 设为 0，固有频率在 `result.freq_Hz` 里。

## 9. 示例清单

| 脚本 | 内容 |
|---|---|
| `example_01_modal_analysis.m` | 固有频率：多种边界、空气/水中 |
| `example_02_viv_shear_flow.m` | 线性剪切流的标准 VIV 算例 |
| `example_03_boundary_comparison.m` | 铰支 / 半刚性 / 固支对比 |
| `example_04_dynamic_tension_sweep.m` | 变轴力反馈系数扫描 |
| `example_05_custom_parameters.m` | 自定义空心管、液体、流速剖面与边界 |
| `example_06_fatigue_rainflow.m` | 雨流疲劳筛查与数据窗口选择 |
| `example_07_tension_options.m` | 四种静力/动力轴力组合对比 |

每个示例开头都有 `FAST_DEMO = true`（粗网格、短时长）；改成 `false` 就是论文
算例的设置。

## 10. 常见问题排查

| 现象 | 原因与解决 |
|---|---|
| `未定义函数或变量 'ctXsfSolveVIV'` | 先运行 `ctXsfSetup`（它把 `lib/`、`src/`、`examples/` 加进路径） |
| `help` 显示“是一个打包文件” | 正常现象：核心是 P-code，只能调用 |
| 报 MATLAB 版本错误 | P-code 需要 R2023a 或更新版本 |
| `N_static_profile contains non-positive tension` | `N_top` 相对跨长太小：增大它，或设 `include_submerged_weight = false` 用恒张力 |
| 改了 `T_total` 但时长没变 | 同时设 `params.nt = ceil(params.T_total/params.dt)`；否则求解器会提示并自动纠正 |
| `DeltaN` 历程全是 0 | `use_variable_tension = false` 表示根本不计算；要“算但不反馈”请用 `true` + `lambda_DeltaN = 0` |
| `custom` 流型报错 | 必须同时给 `flow_profile_z` 与 `flow_profile_U` |
| 空心截面没生效 | 设 `section_type = 'hollow'` 且 `d > 0`；`A`、`I`、`I_inner` 会自动重算 |
| 找不到 DNS 对比文件 | `params.dns.enable` 默认关闭；用它就要把表格放到当前目录或写全路径 |
| 疲劳提示 `INSUFFICIENT_FOR_RAINFLOW` | 末段采样太粗：减小 `dt` 或 `SaveStride`（判据：每周期 ≥ 20 个采样点） |
| 下一个工况的图目录里混进上一个工况的图 | 工况之间调用 `close all`（循环示例里已经这么写） |
| 想得到论文里那套热点分区 | 默认端部区是跨长的 2.5%；设 `params.hotspot_region_fraction = 0.05` 即得论文的 `0--100 / 100--1900 / 1900--2000` |

## 11. 加自己的图或指标

`ctXsfSolveVIV` 返回的 `result` 里有全部结果数组（沿程坐标、包络、RMS、内力、
应力指标、轴力历程、末段时空场、热点表……字段清单见
[model_overview.md](model_overview.md) 末尾）。加一张自己的图只要几行：

```matlab
fig = figure('Color','w');
plot(result.std_Mres, result.z_paper, 'k-', 'LineWidth', 1.5);
xlabel('std(M_{res}) (N·m)'); ylabel('z/D');
ctXsfStyleAxes(gca);                     % 统一风格
ctXsfSaveFig(fig, 'my_own_plot', ctXsfReportOptions(result, params.output));
```

如果要改的是**算法本身**（差分格式、时间积分、尾流方程等），发布包里做不到：
那部分在 `lib/*.p` 里。需要源码做科研合作的话请联系作者。

## 12. 许可、引用与联系方式

MIT 许可，见 [LICENSE](../LICENSE)。使用本代码请引用相关论文与仓库，见
[CITATION.cff](../CITATION.cff)。联系方式见 [README](../README.md#contact)。
