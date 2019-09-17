% PD scheduling weight allocation
function [W_voice,W_video,W_BE,Data_queue,Data_user,Delay_voice_set,Delay_video_set,Delay_BE_set]...
    =MAC_PD_user_basic(Slot_current,N_user,N_slot,Raw_data,T_slot,G,U,QoS,N_service)
% % Slot count
% N_slot=2000;
% % Slot duration
% T_slot=2;
% % Packet number (arriving in 1 ms interval)
% N_packet=T_slot*N_slot;
% Data to be served
Data_queue=zeros(3*N_user,N_slot);
% load('Raw_data.mat','Raw_data');
% % Raw data generation: typical MAC package size in [46,1500] bytes
% % Raw_data=randi([46,1500],3*N_user,T_slot*N_slot);
% Raw_data=zeros(3*N_user,N_packet);
% % R_data=zeros(3*N_user,N_slot);
% % Voice in bits
% Packet_voice=64;
% Raw_data(1:3:end,:)=Packet_voice;
% % Video in bits
% Packet_video_max=420;
% Packet_video_min=120;
% Packet_video_avg=239;
% pd=makedist('Exponential','mu',Packet_video_avg);
% Video_dist=truncate(pd,Packet_video_min,Packet_video_max);
% for Packet_index=1:N_packet
%     for Queue_index=2:3:3*N_user-1
%     Raw_data(Queue_index,Packet_index)=random(Video_dist);
%     end
% end
% % BE in bits
% Packet_BE=500;
% Raw_data(3:3:end,:)=Packet_BE;
% % Guard interval
% G=1;
% % Queue deadline set(Voice, video and BE)
% U=[100 400 1000];
U_voice=U(1);
U_video=U(2);
U_BE=U(3);
% Urgent threshold
Thr_voice=U_voice-G;
Thr_video=U_video-G;
Thr_BE=U_BE-G;
% % QoS set
% QoS=[1024 512 1];
QoS_voice=QoS(1);
QoS_video=QoS(2);
QoS_BE=QoS(3);
% % N_service=[100 75 50];
% N_voice=N_service(1);
% N_video=N_service(2);
% N_BE=N_service(3);
% Initialisation
W_voice=zeros(N_user,U_voice);
W_video=zeros(N_user,U_video);
W_BE=zeros(N_user,U_BE);
% Current time
T_current=Slot_current*T_slot;
% RCD slot //?
Slot_RCD=ones(length(QoS)*N_user,1)*T_current;
% Delay?
Delay_voice_set=zeros(N_user,U_voice);
Delay_video_set=zeros(N_user,U_video);
Delay_BE_set=zeros(N_user,U_BE);
for user_index=1:N_user
    % Remaining packets
    N_voice=N_service(1);
    N_video=N_service(2);
    N_BE=N_service(3);
    %% Case 1: current time <= deadline of voice queue
    if T_current<=U_voice
        % The lth packet arrives at T_packet in [1,T_current]
        for T_packet=1:T_current
            % Packet delay
            Delay=T_current-T_packet;
            Delay_voice_set(user_index,T_packet)=Delay;
            Delay_video_set(user_index,T_packet)=Delay;
            Delay_BE_set(user_index,T_packet)=Delay;
            if Delay >= Thr_voice
                %                 Delay_voice_set(user_index,T_packet)=Delay;
                % Urgent voice packets
                if N_voice>0
                    % W_k,i,l=B_k,i*D_k,i,l
                    W_voice(user_index,T_packet)=QoS_voice*Raw_data(length(QoS)*(user_index-1)+1,T_packet);
                    % Non-urgent packets
                end
            else
                if N_voice>0
                    % W_k,i,l=B_k,i*D_k,i,l/(C_k,i,l+1)
                    W_voice(user_index,T_packet)=QoS_voice*Raw_data(length(QoS)*(user_index-1)+1,T_packet)/(Thr_voice-Delay);
                end
            end
            if N_video>0
                %                 Delay_video_set(user_index,T_packet)=Delay;
                % W_k,i,l=B_k,i*D_k,i,l/(C_k,i,l+1)
                W_video(user_index,T_packet)=QoS_video*Raw_data(length(QoS)*(user_index-1)+2,T_packet)/(Thr_video-Delay);
            end
            if N_BE>0
                %                 Delay_BE_set(user_index,T_packet)=Delay;
                % W_k,i,l=B_k,i*D_k,i,l/(C_k,i,l+1)
                W_BE(user_index,T_packet)=QoS_BE*Raw_data(length(QoS)*(user_index-1)+3,T_packet)/(Thr_BE-Delay);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if N_voice>0
                % Calculates the slot data
                Data_queue((user_index-1)*length(U)+1,Slot_current)=Data_queue((user_index-1)*length(U)+1,Slot_current)+Raw_data(length(QoS)*(user_index-1)+1,T_packet);
                N_voice=N_voice-1;
            end
            if N_video>0
                % Calculates the slot data
                Data_queue((user_index-1)*length(U)+2,Slot_current)=Data_queue((user_index-1)*length(U)+2,Slot_current)+Raw_data(length(QoS)*(user_index-1)+2,T_packet);
                N_video=N_video-1;
            end
            if N_BE>0
                % Calculates the slot data
                Data_queue((user_index-1)*length(U)+3,Slot_current)=Data_queue((user_index-1)*length(U)+3,Slot_current)+Raw_data(length(QoS)*(user_index-1)+3,T_packet);
                N_BE=N_BE-1;
            end
            %%%%%%%%%%%
            if N_voice==0
                Slot_RCD(length(QoS)*(user_index-1)+1)=T_packet;
            end
            if N_video==0
                Slot_RCD(length(QoS)*(user_index-1)+2)=T_packet;
            end
            if N_BE==0
                Slot_RCD(length(QoS)*(user_index-1)+3)=T_packet;
            end
        end
    end
    %% Case 2: deadline of voice queue < current time <= deadline of video queue
    if T_current<=U_video && T_current>U_voice
        for T_packet=T_current-U_voice+1:T_current
            Delay=T_current-T_packet;
            Delay_voice_set(user_index,T_packet-T_current+U_voice)=Delay;
            % Previous voice packets have been dropped
            % The lth voice packet arrives at T_packet in
            % [T_current-U_voice+1,T_current]
            % [-U_voice+1,0] // -T_current
            % [1,U_voice] // +U_voice
            if Delay >= Thr_voice
                %                 Delay_voice_set(user_index,T_packet-T_current+U_voice)=Delay;
                % Urgent voice packets
                if N_voice>0
                    % W_k,i,l=B_k,i*D_k,i,l
                    % T_packet at T_current-U_voice+1,T_packet-(T_current+U_voice)=1;
                    % T_packet at T_current, T_packet-(T_current+U_voice)+1=U_voice;
                    % T_packet-(T_current-U_voice)
                    W_voice(user_index,T_packet-T_current+U_voice)=QoS_voice*Raw_data(length(QoS)*(user_index-1)+1,T_packet);
                    % Non-urgent packets
                end
            else
                if N_voice>0
                    % W_k,i,l=B_k,i*D_k,i,l/(C_k,i,l+1)
                    W_voice(user_index,T_packet-T_current+U_voice)=QoS_voice*Raw_data(length(QoS)*(user_index-1)+1,T_packet)/(Thr_voice-Delay);
                end
            end
            if N_voice>0
                % Calculates the slot data
                Data_queue((user_index-1)*length(U)+1,Slot_current)=Data_queue((user_index-1)*length(U)+1,Slot_current)+Raw_data(length(QoS)*(user_index-1)+1,T_packet);
                if W_voice(user_index,T_packet-T_current+U_voice)>0
                    % Updates the packet index
                    N_voice=N_voice-1;
                    if N_voice==0
                        % Allocates the RCD slots
                        Slot_RCD(length(QoS)*(user_index-1)+1)=T_packet;
                    end
                end
            end
        end
        for T_packet=1:T_current
            Delay=T_current-T_packet;
            Delay_video_set(user_index,T_packet)=Delay;
            Delay_BE_set(user_index,T_packet)=Delay;
            if Delay >= Thr_video
                %                 Delay_video_set(user_index,T_packet)=Delay;
                % Urgent video packets
                if N_video>0
                    % W_k,i,l=B_k,i*D_k,i,l
                    W_video(user_index,T_packet)=QoS_video*Raw_data(length(QoS)*(user_index-1)+2,T_packet);
                    % Non-urgent packets
                end
            else
                if N_video>0
                    % W_k,i,l=B_k,i*D_k,i,l/(C_k,i,l+1)
                    W_video(user_index,T_packet)=QoS_video*Raw_data(length(QoS)*(user_index-1)+2,T_packet)/(Thr_video-Delay);
                end
            end
            if N_BE>0
                %                 Delay_BE_set(user_index,T_packet)=Delay;
                % W_k,i,l=B_k,i*D_k,i,l/(C_k,i,l+1)
                W_BE(user_index,T_packet)=QoS_BE*Raw_data(length(QoS)*(user_index-1)+3,T_packet)/(Thr_BE-Delay);
            end
            %%%%%%%%%%%
            if N_video>0
                % Calculates the slot data
                Data_queue((user_index-1)*length(U)+2,Slot_current)=Data_queue((user_index-1)*length(U)+2,Slot_current)+Raw_data(length(QoS)*(user_index-1)+2,T_packet);
                if W_video(user_index,T_packet)>0
                    % Updates the packet index
                    N_video=N_video-1;
                    if N_video==0
                        Slot_RCD(length(QoS)*(user_index-1)+2)=T_packet;
                    end
                end
            end
            
            % For BE, since the current time < the deadline of
            % video queue, the corresponding packets are non-urgent
            if N_BE>0
                % Calculates the slot data
                Data_queue((user_index-1)*length(U)+3,Slot_current)=Data_queue((user_index-1)*length(U)+3,Slot_current)+Raw_data(length(QoS)*(user_index-1)+3,T_packet);
                if W_BE(user_index,T_packet)>0
                    % Updates the packet index
                    N_BE=N_BE-1;
                    if N_BE==0
                        % Allocates the RCD slots
                        Slot_RCD(length(QoS)*(user_index-1)+3)=T_packet;
                    end
                end
            end
        end
    end
    
    %% Case 3: deadline of video queue < current time <= deadline of BE queue
    if T_current>U_video && T_current<=U_BE
        for T_packet=T_current-U_voice+1:T_current
            Delay=T_current-T_packet;
            Delay_voice_set(user_index,T_packet-T_current+U_voice)=Delay;
            % Previous voice packets have been dropped
            % The lth voice packet arrives at T_packet in
            % [T_current-U_voice+1,T_current]
            % [-U_voice+1,0] // -T_current
            % [1,U_voice] // +U_voice
            if Delay >= Thr_voice
                %                 Delay_voice_set(user_index,T_packet-T_current+U_voice)=Delay;
                % Urgent voice packets
                if N_voice>0
                    % W_k,i,l=B_k,i*D_k,i,l
                    % T_packet at T_current-U_voice+1,T_packet-(T_current+U_voice)=1;
                    % T_packet at T_current, T_packet-(T_current+U_voice)+1=U_voice;
                    % T_packet-(T_current-U_voice)
                    W_voice(user_index,T_packet-T_current+U_voice)=QoS_voice*Raw_data(length(QoS)*(user_index-1)+1,T_packet);
                    % Non-urgent packets
                end
            else
                if N_voice>0
                    % W_k,i,l=B_k,i*D_k,i,l/(C_k,i,l+1)
                    W_voice(user_index,T_packet-T_current+U_voice)=QoS_voice*Raw_data(length(QoS)*(user_index-1)+1,T_packet)/(Thr_voice-Delay);
                end
            end
            if N_voice>0
                % Calculates the slot data
                Data_queue((user_index-1)*length(U)+1,Slot_current)=Data_queue((user_index-1)*length(U)+1,Slot_current)+Raw_data(length(QoS)*(user_index-1)+1,T_packet);
                if W_voice(user_index,T_packet-T_current+U_voice)>0
                    % Updates the packet index
                    N_voice=N_voice-1;
                    if N_voice==0
                        % Allocates the RCD slots
                        Slot_RCD(length(QoS)*(user_index-1)+1)=T_packet;
                    end
                end
            end
        end
        for T_packet=T_current-U_video+1:T_current
            Delay=T_current-T_packet;
            Delay_video_set(user_index,T_packet-(T_current-U_video))=Delay;
            % Previous video packets have been dropped
            % The lth video packet arrives at T_packet in
            % [T_current-U_video+1,T_current]
            % [-U_video+1,0] // -T_current
            % [1,U_video] // +U_video
            if Delay >= Thr_video
                %                 Delay_video_set(user_index,T_packet-(T_current-U_video))=Delay;
                % Urgent video packets
                if N_video>0
                    % W_k,i,l=B_k,i*D_k,i,l
                    W_video(user_index,T_packet-(T_current-U_video))=QoS_video*Raw_data(length(QoS)*(user_index-1)+2,T_packet);
                    % Non-urgent packets
                end
            else
                if N_video>0
                    % W_k,i,l=B_k,i*D_k,i,l/(C_k,i,l+1)
                    W_video(user_index,T_packet-(T_current-U_video))=QoS_video*Raw_data(length(QoS)*(user_index-1)+2,T_packet)/(Thr_video-Delay);
                end
            end
            if N_video>0
                % Calculates the slot data
                Data_queue((user_index-1)*length(U)+2,Slot_current)=Data_queue((user_index-1)*length(U)+2,Slot_current)+Raw_data(length(QoS)*(user_index-1)+2,T_packet);
                if W_video(user_index,T_packet-(T_current-U_video))>0
                    % Updates the packet index
                    N_video=N_video-1;
                    if N_video==0
                        % Allocates the RCD slots
                        Slot_RCD(length(QoS)*(user_index-1)+2)=T_packet;
                    end
                end
            end
        end
        for T_packet=1:T_current
            Delay=T_current-T_packet;
            Delay_BE_set(user_index,T_packet)=Delay;
            if Delay >= Thr_BE
                %                 Delay_BE_set(user_index,T_packet)=Delay;
                % Urgent BE packets
                if N_BE>0
                    % W_k,i,l=B_k,i*D_k,i,l
                    W_BE(user_index,T_packet)=QoS_BE*Raw_data(length(QoS)*(user_index-1)+3,T_packet);
                    % Non-urgent packets
                end
            else
                if N_BE>0
                    % W_k,i,l=B_k,i*D_k,i,l/(C_k,i,l+1)
                    W_BE(user_index,T_packet)=QoS_BE*Raw_data(length(QoS)*(user_index-1)+3,T_packet)/(Thr_BE-Delay);
                end
            end
            if N_BE>0
                % Calculates the slot data
                Data_queue((user_index-1)*length(U)+3,Slot_current)=Data_queue((user_index-1)*length(U)+3,Slot_current)+Raw_data(length(QoS)*(user_index-1)+3,T_packet);
                if W_BE(user_index,T_packet)>0
                    % Updates the packet index
                    N_BE=N_BE-1;
                    if N_BE==0
                        % Allocates the RCD slots
                        Slot_RCD(length(QoS)*(user_index-1)+3)=T_packet;
                    end
                end
            end
        end
    end
    %% Case 4: deadline of BE queue < current time
    if T_current>U_BE
        for T_packet=T_current-U_voice+1:T_current
            Delay=T_current-T_packet;
            Delay_voice_set(user_index,T_packet-T_current+U_voice)=Delay;
            % Previous voice packets have been dropped
            % The lth voice packet arrives at T_packet in
            % [T_current-U_voice+1,T_current]
            % [-U_voice+1,0] // -T_current
            % [1,U_voice] // +U_voice
            if Delay >= Thr_voice
                %                 Delay_voice_set(user_index,T_packet-T_current+U_voice)=Delay;
                % Urgent voice packets
                if N_voice>0
                    % W_k,i,l=B_k,i*D_k,i,l
                    % T_packet at T_current-U_voice+1,T_packet-(T_current+U_voice)=1;
                    % T_packet at T_current, T_packet-(T_current+U_voice)+1=U_voice;
                    % T_packet-(T_current-U_voice)
                    W_voice(user_index,T_packet-T_current+U_voice)=QoS_voice*Raw_data(length(QoS)*(user_index-1)+1,T_packet);
                    % Non-urgent packets
                end
            else
                if N_voice>0
                    % W_k,i,l=B_k,i*D_k,i,l/(C_k,i,l+1)
                    W_voice(user_index,T_packet-T_current+U_voice)=QoS_voice*Raw_data(length(QoS)*(user_index-1)+1,T_packet)/(Thr_voice-Delay);
                end
            end
            if N_voice>0
                % Calculates the slot data
                Data_queue((user_index-1)*length(U)+1,Slot_current)=Data_queue((user_index-1)*length(U)+1,Slot_current)+Raw_data(length(QoS)*(user_index-1)+1,T_packet);
                if W_voice(user_index,T_packet-T_current+U_voice)>0
                    % Updates the packet index
                    N_voice=N_voice-1;
                    if N_voice==0
                        % Allocates the RCD slots
                        Slot_RCD(length(QoS)*(user_index-1)+1)=T_packet;
                    end
                end
            end
        end
        for T_packet=T_current-U_video+1:T_current
            Delay=T_current-T_packet;
            Delay_video_set(user_index,T_packet-(T_current-U_video))=Delay;
            % Previous video packets have been dropped
            % The lth video packet arrives at T_packet in
            % [T_current-U_video+1,T_current]
            % [-U_video+1,0] // -T_current
            % [1,U_video] // +U_video
            if Delay >= Thr_video
                %                 Delay_video_set(user_index,T_packet-(T_current-U_video))=Delay;
                % Urgent video packets
                if N_video>0
                    % W_k,i,l=B_k,i*D_k,i,l
                    W_video(user_index,T_packet-(T_current-U_video))=QoS_video*Raw_data(length(QoS)*(user_index-1)+2,T_packet);
                    % Non-urgent packets
                end
            else
                if N_video>0
                    % W_k,i,l=B_k,i*D_k,i,l/(C_k,i,l+1)
                    W_video(user_index,T_packet-(T_current-U_video))=QoS_video*Raw_data(length(QoS)*(user_index-1)+2,T_packet)/(Thr_video-Delay);
                end
            end
            if N_video>0
                % Calculates the slot data
                Data_queue((user_index-1)*length(U)+2,Slot_current)=Data_queue((user_index-1)*length(U)+2,Slot_current)+Raw_data(length(QoS)*(user_index-1)+2,T_packet);
                if W_video(user_index,T_packet-(T_current-U_video))>0
                    % Updates the packet index
                    N_video=N_video-1;
                    if N_video==0
                        % Allocates the RCD slots
                        Slot_RCD(length(QoS)*(user_index-1)+2)=T_packet;
                    end
                end
            end
        end
        for T_packet=T_current-U_BE+1:T_current
            Delay=T_current-T_packet;
            Delay_BE_set(user_index,T_packet-(T_current-U_BE))=Delay;
            % Previous BE packets have been dropped
            % The lth BE packet arrives at T_packet in
            % [T_current-U_BE,T_current]
            % [-U_BE,0] // -T_current
            % [1,U_BE] // +U_BE
            if Delay >= Thr_BE
                %                 Delay_BE_set(user_index,T_packet-(T_current-U_BE))=Delay;
                % Urgent BE packets
                if N_BE>0
                    % W_k,i,l=B_k,i*D_k,i,l
                    W_BE(user_index,T_packet-(T_current-U_BE))=QoS_BE*Raw_data(length(QoS)*(user_index-1)+3,T_packet);
                    % Non-urgent packets
                end
            else
                if N_BE>0
                    % W_k,i,l=B_k,i*D_k,i,l/(C_k,i,l+1)
                    W_BE(user_index,T_packet-(T_current-U_BE))=QoS_BE*Raw_data(length(QoS)*(user_index-1)+3,T_packet)/(Thr_BE-Delay);
                end
            end
            if N_BE>0
                % Calculates the slot data
                Data_queue((user_index-1)*length(U)+3,Slot_current)=Data_queue((user_index-1)*length(U)+3,Slot_current)+Raw_data(length(QoS)*(user_index-1)+3,T_packet);
                if W_BE(user_index,T_packet-(T_current-U_BE))>0
                    % Updates the packet index
                    N_BE=N_BE-1;
                    if N_BE==0
                        % Allocates the RCD slots
                        Slot_RCD(length(QoS)*(user_index-1)+3)=T_packet;
                    end
                end
            end
        end
    end
end
Data_voice=Data_queue(1:3:end,:);
Data_video=Data_queue(2:3:end,:);
Data_BE=Data_queue(3:3:end,:);
Data_user=Data_voice+Data_video+Data_BE;
testflag=1;