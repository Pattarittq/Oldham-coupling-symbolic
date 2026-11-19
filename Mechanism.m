%% Oldham Coupling Symbolic Kinematics
% Requires Symbolic Math Toolbox.
% A = [0; 0], B = [e; 0]. Positive angles are counterclockwise.
% q1 and q2 locate the disc center relative to A and B along u and v.

clearvars
syms theta omega alpha real
syms e positive
syms q1 q2 real

%% Position from loop closure
A = [0; 0];
B = [e; 0];
u = [cos(theta); sin(theta)];
v = [-sin(theta); cos(theta)];

loop = A + q1*u - B - q2*v;
solution = solve(loop == [0; 0], [q1, q2]);
q = simplify([solution.q1; solution.q2])
C = simplify(A + q(1)*u)
centerRadius = simplify(sqrt(sum((C - (A+B)/2).^2)), 'Steps', 50)

%% Velocity and acceleration
% The prismatic joints fix the relative orientation of the hubs.
% With both angles zeroed at the starting position:
outputAngle = theta;
outputSpeed = omega;

% Chain rule with omega = dtheta/dt and alpha = domega/dt.
qDot = simplify(diff(q, theta)*omega)
qDDot = simplify(diff(q, theta, 2)*omega^2 + diff(q, theta)*alpha)

%% Numerical check for the proposed geometry
offset_mm = 8;
input_rpm = 6;
omega_rad_s = input_rpm*2*pi/60;
theta_deg = (0:360).';
theta_rad = deg2rad(theta_deg);

qModel = matlabFunction(subs(q, e, offset_mm), 'Vars', theta);
centerModel = matlabFunction(subs(C, e, offset_mm), 'Vars', theta);
speedModel = matlabFunction(subs(qDot, [e, omega], ...
    [offset_mm, omega_rad_s]), 'Vars', theta);

% Evaluate the two-component symbolic functions at scalar input angles.
q_mm = zeros(numel(theta_rad), 2);
center_mm = zeros(size(q_mm));
qSpeed_mm_s = zeros(size(q_mm));
for k = 1:numel(theta_rad)
    angle = theta_rad(k);
    q_mm(k,:) = qModel(angle).';
    center_mm(k,:) = centerModel(angle).';
    qSpeed_mm_s(k,:) = speedModel(angle).';
end

sample = [1, 91, 181, 271];
disp(table(theta_deg(sample), q_mm(sample,1), q_mm(sample,2), ...
    'VariableNames', {'Input_deg', 'q1_mm', 'q2_mm'}))
travel_mm = max(q_mm, [], 1) - min(q_mm, [], 1)
assert(all(abs(travel_mm - 2*offset_mm) < 1e-10))
radius_mm = hypot(center_mm(:,1) - offset_mm/2, center_mm(:,2));
assert(all(abs(radius_mm - offset_mm/2) < 1e-10))

%% Plots
figure('Name', 'Oldham Coupling Kinematics')
tiledlayout(2, 2)

nexttile
plot(theta_deg, q_mm, 'LineWidth', 1.5)
xlabel('Input angle (deg)')
ylabel('Displacement (mm)')
legend('q_1', 'q_2', 'Location', 'best')
grid on

nexttile
plot(theta_deg, qSpeed_mm_s, 'LineWidth', 1.5)
xlabel('Input angle (deg)')
ylabel('Sliding velocity (mm/s)')
legend('dq_1/dt', 'dq_2/dt', 'Location', 'best')
grid on

nexttile
plot(center_mm(:,1), center_mm(:,2), 'LineWidth', 1.5)
hold on
plot([0, offset_mm], [0, 0], 'ko', 'MarkerFaceColor', 'k')
axis equal
xlabel('x (mm)')
ylabel('y (mm)')
title('Floating disc center')
grid on

nexttile
plot(theta_deg, theta_deg, 'LineWidth', 1.5)
xlabel('Input angle (deg)')
ylabel('Output angle (deg)')
axis equal tight
grid on
