clear;
% user_set=8:8:72;
% Eb_N0_dB=20;
% PD_delay_voice_avg=[1.2982 1.5760 4.3942 5.4381 7.1031 8.5788 9.8595 11.0639 12.7200];
% MLWDF_delay_voice_avg=[1.4025 1.6097 3.0671 4.918 10.7516 16.4757 25.3312 33.5637 41.4917];
% PD_delay_video_avg=[1.4258 3.9098 7.1031 12.9987 21.1444 37.0639 77.4927 181.0575 351.7972];
% MLWDF_delay_video_avg=[1.9817 5.7441 11.9807 33.1009 128.9300 311.5548 359.1695 368.4016 373.1953];
% PD_pkt_drop_rate_voice=[0 0 0 0 0 0 0 0 0];
% MLWDF_pkt_drop_rate_voice=[0 0 0 0 0 0 0 0 0];
% PD_pkt_drop_rate_video=[0 0 0 0 0 1.0417e-04 0.0027 0.0083];
% PD_pkt_drop_rate_BE=[0 0 0 0.3826 0.6439 0.7991	0.8819	0.9401	0.9739];
% MLWDF_pkt_drop_rate_BE=[0 0 0 0.4974 0.7972 0.8977	0.9440	0.9772	0.9949];
% PD_throughput=[1.3152 2.3776 3.1913	3.4383	3.5861	3.7603	3.8541 3.9212 4.0157];
% MLWDF_throughput=[1.2943 2.3470 2.9994 3.2528 3.3759 3.4810 3.5083 3.5277 3.5324];

load('PD_SNR_advanced.mat');
load('MLWDF_SNR_advanced.mat');

figure(1);
plot(Eb_N0_dB,PD_delay_haptic_avg,'k^--');
hold on;
plot(Eb_N0_dB,MLWDF_delay_haptic_avg,'ro-');
xlabel('SNR (dB)');
ylabel('Average haptic packet delay (ms)');
legend('PD','M-LWDF','location','NorthEast');
grid on;

figure(2);
plot(Eb_N0_dB,PD_delay_voice_avg,'k^--');
hold on;
plot(Eb_N0_dB,MLWDF_delay_voice_avg,'ro-');
xlabel('SNR (dB)');
ylabel('Average voice packet delay (ms)');
legend('PD','M-LWDF','location','NorthEast');
grid on;

figure(3);
plot(Eb_N0_dB,PD_pkt_drop_rate_haptic,'k^--');
hold on;
plot(Eb_N0_dB,MLWDF_pkt_drop_rate_haptic,'ro-');
xlabel('SNR (dB)');
ylabel('Haptic packet drop rate');
legend('PD','M-LWDF','location','NorthEast');
grid on;

figure(4);
plot(Eb_N0_dB,PD_pkt_drop_rate_voice,'k^--');
hold on;
plot(Eb_N0_dB,MLWDF_pkt_drop_rate_voice,'ro-');
xlabel('SNR (dB)');
ylabel('Voice packet drop rate');
legend('PD','M-LWDF','location','NorthEast');
grid on;

figure(5);
plot(Eb_N0_dB,PD_throughput,'k^--');
hold on;
plot(Eb_N0_dB,MLWDF_throughput,'ro-');
xlabel('SNR (dB)');
ylabel('System throughput (bps/Hz)');
legend('PD','M-LWDF','location','NorthWest');
grid on;

flag=1;