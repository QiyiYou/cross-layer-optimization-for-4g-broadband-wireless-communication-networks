clear;
load('MLWDF_outage_probability_haptic.mat');
load('PD_outage_probability_haptic.mat');

figure(1);
plot(sort(PD_delay_haptic_temp), linspace(1-1/length(PD_delay_haptic_temp), 0, length(PD_delay_haptic_temp)),'k-');
hold on;
plot(sort(MLWDF_delay_haptic_temp), linspace(1-1/length(MLWDF_delay_haptic_temp), 0, length(MLWDF_delay_haptic_temp)),'r-');
xlabel('Haptic packet delay (ms)');
ylabel('Delay outage probability');
legend('PD','M-LWDF','location','NorthEast');
grid on;

figure(2);
plot(sort(PD_delay_voice_temp), linspace(1-1/length(PD_delay_voice_temp), 0, length(PD_delay_voice_temp)),'k-');
hold on;
plot(sort(MLWDF_delay_voice_temp), linspace(1-1/length(MLWDF_delay_voice_temp), 0, length(MLWDF_delay_voice_temp)),'r-');
xlabel('Voice packet delay (ms)');
ylabel('Delay outage probability');
legend('PD','M-LWDF','location','NorthEast');
grid on;

flag=1;