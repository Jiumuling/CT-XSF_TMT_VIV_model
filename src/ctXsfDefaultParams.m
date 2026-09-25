function params = ctXsfDefaultParams()
%CTXSFDEFAULTPARAMS  Default parameter set of the CT-XSF 2-DOF mixed
%   Timoshenko beam - wake oscillator VIV framework.
%
%   PARAMS = CTXSFDEFAULTPARAMS() returns the documented parameter structure
%   used by CTXSFSOLVEVIV.  Every field can be modified by the user before
%   the solver is called, for example
%
%       ctXsfSetup;
%       params = ctXsfDefaultParams();
%       params.D = 0.03;                      % [A] rod diameter
%       params.rho = 1025;                    % [B] sea water
%       params.flow_profile = 'uniform';      % [C] uniform current
%       params.U_top = 1.0;
%       params.boundary_preset = 'semi_rigid_both';   % [D]
%       params.Nz_total = 401;                % [G] quick grid
%       params.T_total = 10;                  % [G] short record
%       params.output.figures = {'displacement','internal_force','fatigue'};
%       result = ctXsfSolveVIV(params);       % protected core solver
%       ctXsfReport(result, params.output);   % selectable public report
%
%   Parameter groups
%     [A] Beam / rod parameters          geometry, section, material
%     [B] Fluid parameters               external / internal fluid
%     [C] Flow and flow-profile          velocity magnitude and shape
%     [D] Boundary conditions            preset, stiffness, damping
%     [E] Hydrodynamic and wake model    empirical coefficients
%     [F] Static and dynamic tension     top tension, axial-tension feedback
%     [G] Numerical parameters           mesh, time stepping, coupling, stats
%     [H] Output control                 folders, figure selection, exports
%     [I] Reference data (optional)      DNS / experimental RMS comparison
%     [J] Modal analysis                 number of modes, dry / still water
%
%   Derived quantities (masses per unit length, section quantities, tension
%   profile, ...) are computed inside CTXSFSOLVEVIV from the primitive
%   parameters listed above, so there is no need to edit them here.
%
%   See also CTXSFSOLVEVIV, CTXSFSETUP, CTXSFREPORT.

params = struct();

%% ===================== [A] 杆件参数 Beam / rod =====================
% 几何量：外径 D、内径 d、长度 L（单位：m）。d = 0 为实心圆柱/拉索。
params.D = 0.02;                  % 外径
params.d = 0.0;                   % 内径（空心管用；实心时取 0）
params.L = 40.0;                  % 长度，本算例 L/D = 2000

% 截面类型：'solid'（实心）或 'hollow'（空心管）。
% A、I、Ap、I_inner 会根据 D、d 自动计算，无需手改。
params.section_type = 'solid';

% 材料参数：结构密度、杨氏模量、泊松比。
params.rhos  = 2546.5;            % 结构密度 kg/m^3
params.E     = 2.045e9;           % 杨氏模量 Pa
params.nu    = 0.30;              % 泊松比

% Timoshenko 梁剪切修正系数。kGA 越大越接近 Euler-Bernoulli 梁。
params.kappa = 3/4;

% 由上述量导出的截面量与刚度量（一般不需要手工修改）。
params.dd = params.D/2;
if strcmpi(params.section_type, 'hollow')
    params.A = pi*(params.D^2 - params.d^2)/4;
    params.I = pi*(params.D^4 - params.d^4)/64;
else
    params.A = pi*params.D^2/4;
    params.I = pi*params.D^4/64;
end
params.Ap      = params.A;            % 动态附加轴力计算使用的截面积
params.I_inner = pi*params.d^4/64;    % 内腔截面惯性矩（内水转动惯量用）

params.G   = params.E/(2*(1+params.nu));
params.kGA = params.kappa * params.G * params.A;

%% ===================== [B] 液体参数 Fluid =====================
params.rho       = 1000;          % 外部流体密度 kg/m^3
params.rho_inner = 0;             % 内部流体密度 kg/m^3

% 外部附加质量系数：单位长度附加质量 m_a = eta * rho * pi * D^2 / 4。
% 经典 VIV 经验取值 eta ≈ 1.0；如需抑制/增强附加质量效应可直接修改。
params.eta = 1.0;

% 重力加速度（用于单位长度浮重 w = g*(m_s + m_w - m_f)）。
params.g = 9.8;

%% ===================== [C] 流速与流型 Flow and flow profile =====================
% 斯特劳哈尔数：涡脱落频率 f_s = St * U / D。
params.St = 0.2;

% 来流剖面类型（内部坐标 z = 0 位于顶端）：
%   'linear_shear' ：U(z) = U_top - (U_top - U_bottom)*z/L，顶部流速最大；
%                    beta = 0 时退化为均匀流。
%   'uniform'      ：U(z) = U_top，均匀来流。
%   'custom'       ：由 params.flow_profile_z / params.flow_profile_U 给出的
%                    (z, U) 点对线性插值，可描述实测剖面或非剪切流型。
params.flow_profile = 'linear_shear';

params.U_top = 0.5;                            % 顶端来流速度 m/s
params.beta  = 0.7;                            % 剪切强度：U_bottom = (1-beta)*U_top
params.U_bottom = (1 - params.beta) * params.U_top;

% 仅当 flow_profile = 'custom' 时才需要下面的剖面数据（z 为内部坐标，0 在顶端）：
% params.flow_profile_z = [0; 0.5*params.L; params.L];
% params.flow_profile_U = [0.60;      0.45;      0.30];

%% ===================== [D] 边界条件参数 Boundary conditions =====================
% 【本质边界 vs 自然边界】
% 本质边界直接规定未知量本身，例如：
%   clamped: u = 0, theta = 0
%   pinned : u = 0, M = 0（u=0 是本质边界，M=0 是自然边界）
% 自然边界规定内力/弯矩，例如：
%   free   : R = 0, M = 0
%   guided : theta = 0, R = 0
%
% 代码中的实现思路是：
%   1）本质边界通过替换矩阵行实现，例如 u_edge = 0 或 theta_edge = 0；
%   2）自然边界通过鬼点关系实现，例如 M=0 -> theta_z=0 -> theta_ghost=theta_neighbor；
%   3）半刚性/弹性边界也是自然边界推广，把 Ktheta、Ku、Ctheta、Cu 写进鬼点关系。
%
% 可选边界预设：
%   'pinned_pinned'                    两端铰支：u = 0, M = 0
%   'clamped_clamped'                  两端固支：u = 0, theta = 0
%   'free_free'                        两端自由：R = 0, M = 0
%   'guided_guided'                    两端导向：theta = 0, R = 0
%   'cantilever_left_clamped_right_free'   z=0 固支、z=L 自由
%   'left_pinned_right_free'           z=0 铰支、z=L 自由
%   'left_clamped_right_pinned'        z=0 固支、z=L 铰支
%   'semi_rigid_both'                  两端 u = 0 且 M + Ktheta*theta + Ctheta*theta_t = 0
%   'elastic_both'                     两端 R + Ku*u + Cu*u_t = 0 且 M + Ktheta*theta + Ctheta*theta_t = 0
%   'manual'                           使用下面手工填写的 params.bc.left/right
params.boundary_preset = 'pinned_pinned';

% 弹性/半刚性边界的参考刚度尺度（推荐用倍数而不是绝对刚度）：
%   Ktheta_ref = EI/L    ：端部转动刚度量级，单位 N*m/rad
%   Ku_ref     = EI/L^3  ：端部平动刚度量级，单位 N/m
params.bcPreset.KthetaFactor = 90.0;
params.bcPreset.KuFactor     = 1.0;
params.bcPreset.Ctheta       = 0.0;      % 转动阻尼 N*m*s/rad
params.bcPreset.Cu           = 0.0;      % 平动阻尼 N*s/m

% 手工边界设置，仅当 params.boundary_preset = 'manual' 时生效。
params.bc.left.type  = 'pinned';
params.bc.right.type = 'pinned';

params.bc.left.Ku  = 0.0;          % 平动刚度 N/m，仅 elastic 边界使用
params.bc.left.Cu  = 0.0;          % 平动阻尼 N*s/m，仅 elastic 边界使用
params.bc.right.Ku = 0.0;
params.bc.right.Cu = 0.0;

params.bc.left.Ktheta  = 0.0;      % 转动刚度 N*m/rad，semi_rigid / elastic 使用
params.bc.left.Ctheta  = 0.0;      % 转动阻尼 N*m*s/rad，semi_rigid / elastic 使用
params.bc.right.Ktheta = 0.0;
params.bc.right.Ctheta = 0.0;

% 边界参数是否进入时域/模态方程的规则：
%   stiffness_in_time  = true  -> Ku/Ktheta 进入 Newmark 时域矩阵
%   damping_in_time    = true  -> Cu/Ctheta 进入 Newmark 矩阵和右端项
%   stiffness_in_modal = true  -> Ku/Ktheta 进入 K*phi = omega^2*M*phi
%   damping_in_modal   = false -> 普通固有频率分析按无阻尼处理
params.boundary_damping_in_time     = true;
params.boundary_stiffness_in_time   = true;
params.boundary_stiffness_in_modal  = true;
params.boundary_damping_in_modal    = false;

%% ===================== [E] 水动力与尾流振子系数 =====================
% 重要开关：
%   若 params.CL0 == 0，程序直接进入模态分析模式（不做时域 VIV 计算）。
%   若 params.CL0 ~= 0，程序进入二自由度 VIV 时域求解。
params.CL0 = 0.3;                 % 升力系数幅值；设为 0 时只做模态分析
params.CD0 = 0.2;                 % 脉动阻力系数
params.C_D = 1.2;                 % 平均阻力系数

% 尾流振子参数。p 对应顺流阻力振荡，q 对应横流升力振荡。
params.Ax = 12;
params.Ay = 12;
params.epsilon_x = 0.3;
params.epsilon_y = 0.3;

%% ===================== [F] 静轴力与动态轴力 feedback =====================
% 轴力由两部分组成，二者都可由用户独立选择：
%   静力部分  N_static(z) = N_top - w*z            （w 由 include_submerged_weight 决定）
%   动力部分  N_eff(z,t)  = N_static(z) + lambda_DeltaN * DeltaN(t)
%   附加轴力  DeltaN(t)   = E*Ap/(2L) * int_0^L ( X_z^2 + Y_z^2 ) dz
%
% ---------------------------------------------------------------------
% 开关 1：静张力是否包含自重/浮重引起的线性变化
% ---------------------------------------------------------------------
%   true （默认）：w = g*(m_s + m_w - m_f)，静张力沿跨长线性变化，
%                  顶端 N_top 最大，底端 N_top - w*L 最小。
%   false        ：w = 0，沿跨长恒定静张力 N_static(z) = N_top。
% 若只想改变 w 的大小（例如预留浮力、含内流体的管），可直接修改 params.g，
% 或修改下面的 params.w 覆盖值（见 params.use_user_defined_w）。
params.include_submerged_weight = true;

% 可选：直接指定单位长度浮重 w（N/m），用于覆盖上面的自动计算。
%   params.use_user_defined_w = true 时生效。
params.use_user_defined_w = false;
params.w_user_defined     = 0.0;     % 例如 0 表示恒张力，4.0 表示自重引起的线性轴力

% ---------------------------------------------------------------------
% 开关 2：是否计入振动引起的动态附加轴力 DeltaN(t)
% ---------------------------------------------------------------------
%   true （默认）：每个时间步根据几何伸长计算 DeltaN(t)，并按 lambda_DeltaN
%                  反馈进结构刚度矩阵（矩阵随之重新组装）。
%   false        ：完全不计动态轴力，DeltaN 不计算、输出为 0；
%                  结构矩阵固定，可预先 LU 分解，计算最快。
% 注意：若想“计算并输出 DeltaN，但不反馈到结构”，请保持
%   use_variable_tension = true 且 lambda_DeltaN = 0，
%   这时仍然给出 DeltaN(t) 时间历程，只是不改变结构刚度。
params.use_variable_tension = true;

% 动态附加轴力反馈强度系数：
%   1   -> 完整反馈，N_eff = N_static + DeltaN(t)
%   0   -> 只计算/输出 DeltaN，不反馈（见上面的说明）
%   0~1 -> 连续敏感性分析用
params.lambda_DeltaN = 1.0;

% 顶端静张力（N）。无论上面如何选择，静张力都以此为顶端基准值。
params.N_top = 2.45e2;

% ---------------------------------------------------------------------
% 四种典型组合（均受支持，可按需选择）
%   1) 自重线性轴力 + 变轴力反馈：
%        include_submerged_weight = true , use_variable_tension = true , lambda_DeltaN = 1
%   2) 自重线性轴力 + 不含变轴力：
%        include_submerged_weight = true , use_variable_tension = false
%   3) 恒定静张力 + 变轴力反馈：
%        include_submerged_weight = false, use_variable_tension = true , lambda_DeltaN = 1
%   4) 恒定静张力 + 只输出 DeltaN 不反馈：
%        include_submerged_weight = false, use_variable_tension = true , lambda_DeltaN = 0
% 例：examples/example_07_tension_options.m 会直接对比这四种组合。
% ---------------------------------------------------------------------

%% ===================== [G] 数值参数 Numerical parameters =====================
% 空间网格与时间步。精细网格/长时间对论文算例更准确，但耗时成比例增加。
% 论文中的 L/D = 2000 算例使用 Nz_total = 4001, dt = 5e-4 s 左右。
params.Nz_total = 1001;            % 空间节点数

params.T_total  = 30.0;            % 总模拟时长 s
params.dt       = 0.01;            % 时间步长 s
params.nt       = ceil(params.T_total/params.dt);

% Newmark-beta 参数。beta=1/4, gamma=1/2 为平均加速度法，线性系统无条件稳定。
params.betaN  = 1/4;
params.gammaN = 1/2;

% 强耦合迭代参数：每个时间步内反复更新结构、尾流和动态轴力，直到残差收敛。
params.kmax_couple = 8;
params.couple_tol  = 1e-7;
params.eps_norm    = 1e-14;
params.relax_wake  = 0.8;

% 统计窗口：只用最后一段稳定响应计算 RMS、均值、最大值等。
params.rms_tail_fraction = 0.30;   % 最后 30% 时间窗

% 保存末段响应，用于热图、时空图与内力/应力对比。
% TailTime 是保留的末段时长；若设置了 tail_time_fraction，则由它换算
%   TailTime = tail_time_fraction * T_total    （留空 = 使用下面的 TailTime）
params.TailTime   = min(10.0, params.T_total * 0.30);
params.tail_time_fraction = [];     % 例如 0.30 = 保留最后 30% 时长
params.SaveStride = 10;

% 绘图参数：频谱图横坐标上限（0--100 rad/s 通常覆盖主要 VIV 频率）。
params.plot.spectrum_omega_max = 100;

% Chaplin 风格坐标轴控制：false 自动范围；true 固定范围便于多工况对比。
params.use_fixed_chaplin_axes = false;

%% ===================== [H] 输出控制 Output control =====================
params.case_id = '';                         % 留空时自动生成 case_id

% 是否输出 Excel / MAT 数据文件。
params.output.enable_export = true;

% 输出目录 / 图像目录：留空（''）时 ctXsfSolveVIV 在当前工作目录下自动创建
%   CTXSF_outputs_<yyyymmdd_HHMMSS>/ 与其中的 figures/ 子目录。
% 需要固定目录时可直接赋值，例如 params.output.out_dir = 'D:\runs\case01';
params.output.out_dir    = '';
params.output.figure_dir = '';

% 是否保存 ctXsfSolveVIV 内置的完整报告图（PNG + FIG）。
params.output.save_fig = true;

% false：内置报告图仍然生成，但不弹出窗口，适合批处理 / 服务器。
params.output.make_plots = true;

% 实心圆截面最大剪应力近似系数：tau_max ≈ factor * Q / A。
% 只想得到名义剪应力时取 1。
params.output.tau_shear_factor = 4/3;

% ---------------------------------------------------------------------
% 可选输出的选择开关（由公开的 CTXSFREPORT 使用，也可自行读取该字段）：
%   'displacement'   位移关键信息：包络、RMS、时空图、轨迹、频谱
%   'internal_force' 内力：弯矩/剪力沿程统计、真值与位移假设对比
%   'fatigue'        疲劳/应力：sigma_b、tau_Q 包络与热图、热点分区表
%   'wake'           尾流变量 p、q 的 RMS 分布
%   'time_space'     位移时空热图
%   'tension'        动态附加轴力时间历程与分量
%   'all'            以上全部
% 例：params.output.figures = {'displacement','fatigue'};
params.output.figures = {'all'};

% ---------------------------------------------------------------------
% 说明：ctXsfSolveVIV 内部控制着原论文所用的一整套报告图（总开关为
% params.output.make_plots / save_fig）。若只需要挑选部分输出，
% 使用公开层 ctXsfReport(result, params.output) 并按
% params.output.figures 选择分组即可。

%% ===================== [I] 参考数据对比（可选） =====================
% 读取外部 DNS / 实验 RMS 数据并与本模型对比。默认关闭；
% 打开前请确认 params.dns.file 指向存在的表格文件，否则会报错。
params.dns.enable = false;
params.dns.file   = 'red_and_purple.xlsx';
params.dns.sheet  = 1;
params.dns.cols   = [4, 5];                  % 默认 [Y_rms/D, z_raw]
params.dns.col_order = 'rms_z';              % 'rms_z' 或 'z_rms'
params.dns.header_lines = 2;                 % 前两行为表头则设为 2
params.dns.z_mode = 'gao_reverse';           % 'gao_reverse'/'auto'/'physical'/'dimensionless'
% 若参考曲线方向与本模型相反，只翻转参考数据的 RMS 序列。
params.dns.flip_rms = true;
params.dns.error_grid_N = 1601;              % 与参考数据对齐的统一网格点数

%% ===================== [J] 模态分析参数 Modal analysis =====================
params.modal_n_modes = 10;                   % 输出前若干阶固有频率

% 'water'：水中模态，包含外部附加质量
% 'air'  ：空气中模态，不包含外部附加质量
params.modal_environment = 'water';

% 若为 true，则在模态分析中按 modal_environment 重新计算自重/浮重导致的
% 张力梯度；为 false 时保持与此时域分析相同的静张力分布，便于只对比附加质量影响。
params.modal_recompute_weight = false;

%% ===================== [K] 疲劳后处理参数 Fatigue post-processing =====================
% 基于雨流计数的“相对循环应力需求”筛查（公开层 ctXsfFatigueRainflow 与
% ctXsfReport 的 'fatigue' 分组使用）。该指标只用于沿跨长热点排序，
% 不是绝对疲劳寿命：不引入材料 S-N 常数、平均应力修正与长期海况分布。
%
% 计算方式：对每个截面、每个环向角 phi（共 n_phi 个）计算弯曲应力时程
%   sigma_b(phi) = (D/2)/I * (Mx cos(phi) + My sin(phi))
% 并对等效应力 sigma_eq = sqrt(sigma_b,res^2 + 3*tau_Q^2) 做雨流计数，
%   D(m) = sum( count * range^m )
% 再按沿跨长最大值归一化，得到相对需求指标 D_rel。
params.fatigue.enable = true;         % 是否在 'fatigue' 分组中计算雨流指标
params.fatigue.make_figures = true;   % 是否输出疲劳指标图
params.fatigue.m_values = [3 5];      % S-N 曲线斜率指数（可给多组）
params.fatigue.n_phi = 36;            % 环向搜索角度数（越大越精细、越慢）
% 分区（论文坐标 z/D：底端 0，顶端 L/D）。留空 [] 时自动取
%   [0 100; 100 L/D-100; L/D-100 L/D]。
params.fatigue.regions_z_over_D_paper = [];
params.fatigue.region_names = {};     % 留空时自动命名
params.fatigue.min_samples_per_period = 20;     % 采样充分性判据（建议 >= 20）
params.fatigue.warning_samples_per_period = 10; % 警戒判据（>= 10 且 < 20）
params.fatigue.psd_power_threshold = 0.05;      % 频谱显著能量阈值

end
