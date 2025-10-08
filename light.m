clc; clear; close all; %清除一切

%%  參數設定
x1 = -15;  y1 = 0;     % 光源點 
x2 = 15;   y2 = 0;     % 聚焦點 
n1 = 1.0;              % 空氣折射率
n2 = 1.5;              % 透鏡折射率

%%  透鏡設定
h = linspace(0, 5, 50);  % 透鏡高度，取樣點為50

% 建立透鏡曲面 x 座標的陣列，準備依照折射條件逐步填入形狀。
left = nan(size(h));    % 左曲面 (由空氣射入)
right = nan(size(h));   % 右曲面 (由透鏡射出)

%%  設計透鏡表面
%根據Snell's law 反推透鏡入射與出射曲面
%計算左側透鏡表面(光線從空氣進入透鏡)

for i = 1:length(h) % 針對每一條高度為h(i)的光線

    y = h(i);

%計算光源點到暫定折射點(x=0,y) 的入射角 θ_in

    theta_in = atan2(y - y1, 0 - x1);

    % 利用Monte-Carlo隨機產生 N 個可能的法線角度 alpha (與 y 軸夾角)
    N = 10000;  
    alpha_samples = pi * (rand(1, N) - 0.5); 

    % 將每個候選的法線角度 alpha 代入 Snell's Law
    % 計算入射角與折射角是否滿足折射條件
    snell_vals = n1 * sin(theta_in - alpha_samples) - n2 * sin(-alpha_samples);

    % 找出誤差最小的 alpha，即最接近滿足 Snell's Law 的法線方向
    [~, idx] = min(abs(snell_vals));
    alpha = alpha_samples(idx);

    % 將法線角度轉換為曲面切線角度（法線逆時針旋轉 90 度）
    tangent_angle = alpha - pi/2;       % 切線與 x 軸的角度
    slope = tan(tangent_angle);         % 計算該處透鏡表面的切線斜率

    % 根據斜率對高度積分，計算對應的 x 座標位置
    if i == 1
        left(i) = 0;           % 設定初始點在原點 x = 0
    else
        dy = h(i) - h(i-1);              % 相鄰兩點的 y 差距
        dx = dy / slope;                 % 由斜率計算對應的 x 增量
        left(i) = left(i-1) + dx;   % 累積求得 x 座標
    end
end

% 計算右側透鏡表面(光線從透鏡射出回到空氣)

for i = 1:length(h)
    y = h(i); 

    % 設定右側初始點為左側末點往右偏移一小段距離（確保透鏡有厚度）
    if i == 1
        right(i) = left(end) + 2;
    else
        right(i) = right(i-1);  % 從前一點延伸
    end

    % 計算從當前折射點 (x, y) 指向聚焦點的出射方向角度 θ_out
    theta_out = atan2(y2 - y, x2 - right(i));

    N = 10000;
    % 改用等距角度掃描取代隨機取樣，提升計算穩定性
    alpha_samples = (-pi/2) + pi * (0:N-1)/N;  
    snell_vals = n2 * sin(-alpha_samples) - n1 * sin(theta_out - alpha_samples);
    [~, idx] = min(abs(snell_vals));
    alpha = alpha_samples(idx);

    % 將法線角度轉為切線角度並計算斜率
    tangent_angle = alpha - pi/2;
    slope = tan(tangent_angle);

    % 根據斜率積分出右側透鏡表面對應的 x 座標
    if i == 1
        right(i) = right(i);  % 起始點不變
    else
        dy = h(i) - h(i-1);
        dx = dy / slope;
        right(i) = right(i-1) + dx;
    end
end

%% 繪圖 

figure(1); hold on; axis equal; grid on;
xlabel('x'); ylabel('y');
title('Point Focusing Through Refraction');

% 畫出透鏡
plot(left, h, 'k', 'LineWidth', 2, 'HandleVisibility','off');
plot(right, h, 'k', 'LineWidth', 2, 'HandleVisibility','off');
plot(left, -h, 'k', 'LineWidth', 2, 'HandleVisibility','off');
plot(right, -h, 'k', 'LineWidth', 2, 'HandleVisibility','off');

% 畫出光源與聚焦點
plot(x1, y1, 'go', 'MarkerSize', 10, 'DisplayName', '點光源');
plot(x2, y2, 'bo', 'MarkerSize', 10, 'DisplayName', '聚焦點');

% 繪製上半部光線（正 y）通過透鏡的路徑
first = true; % 讓第一條加入圖例
for i = 1:5:length(h)
    y = h(i);
    x_lens_L = left(i);
    x_lens_R = right(i);

    if first
        plot([x1, x_lens_L], [y1, y], 'g', 'DisplayName', '入射光線');
        plot([x_lens_L, x_lens_R], [y, y], 'm', 'DisplayName', '透鏡內平行光線');
        plot([x_lens_R, x2], [y, y2], 'b', 'DisplayName', '折射聚焦光線');
        legend('show', 'AutoUpdate','off');  % 鎖定圖例內容
        first = false;
    else
        plot([x1, x_lens_L], [y1, y], 'g', 'HandleVisibility','off');
        plot([x_lens_L, x_lens_R], [y, y], 'm', 'HandleVisibility','off');
        plot([x_lens_R, x2], [y, y2], 'b', 'HandleVisibility','off');
    end
end

% 繪製下半部光線（負 y）通過透鏡的路徑
for i = 1:5:length(h)
    y = -h(i);
    x_lens_L = left(i);
    x_lens_R = right(i);
    plot([x1, x_lens_L], [y1, y], 'g', 'HandleVisibility','off');
    plot([x_lens_L, x_lens_R], [y, y], 'm', 'HandleVisibility','off');
    plot([x_lens_R, x2], [y, y2], 'b', 'HandleVisibility','off');
end

hold off;
