clear;
%-------------%
P_total=1;
Eb_N0_dB=20;
T_slot=2;
B=5e6;
N_path=6;
N_channel=1;
user_set=8:8:72;
N_user_set=length(user_set);
N_user_max=user_set(N_user_set);
N_sc=512;
N_slot=2000;
N_service_type=3;
N_packet=N_slot*T_slot;
U=[100 400 1000];
U_voice=U(1);
U_video=U(2);
U_BE=U(3);
N_service=[100 400 1000];
N_voice=N_service(1);
N_video=N_service(2);
N_BE=N_service(3);
QoS=[1024 512 1];
G=1;
% Queue maximum allowed probability that S_i(HOL package delay)>U_i(delay
% tolerance) // cited & to be modified
Delta=[0.05,0.05,0.77];

PD_delay_voice_avg=zeros(1,N_user_set);
PD_delay_video_avg=zeros(1,N_user_set);
PD_delay_BE_avg=zeros(1,N_user_set);
PD_capacity_MWC_eq=zeros(1,N_user_set);
PD_capacity_MWC_WWF=zeros(1,N_user_set);
PD_pkt_drop_rate_voice=zeros(1,N_user_set);
PD_pkt_drop_rate_video=zeros(1,N_user_set);
PD_pkt_drop_rate_BE=zeros(1,N_user_set);
for user_set_index=1:N_user_set
    N_user=user_set(user_set_index);
    %-------------%
    T_duration_mean=160;
    Raw_data=zeros(N_service_type*N_user,N_packet);
    % Assumption
    % Voice in bits
    Packet_voice=64;
    Raw_data(1:N_service_type:end,:)=Packet_voice;
    % Video in bits
    Packet_video_max=420;
    Packet_video_min=120;
    Packet_video_avg=239;
    pd=makedist('Exponential','mu',Packet_video_avg);
    Video_dist=truncate(pd,Packet_video_min,Packet_video_max);
    for user_index=1:N_user
        N_packet_left=N_slot*T_slot;
        Position=1;
        while (N_packet_left>0)
            Duration=fix(exprnd(T_duration_mean));
            if Duration<N_packet_left
                Raw_data(N_service_type*(user_index-1)+2,Position:Position+Duration-1)=random(Video_dist);
                N_packet_left=N_packet_left-Duration;
                Position=Position+Duration;
            else
                Raw_data(N_service_type*(user_index-1)+2,Position:Position+N_packet_left-1)=random(Video_dist);
                Position=Position+N_packet_left;
                N_packet_left=0;
            end
        end
    end
    % for Packet_index=1:N_packet
    %     for Queue_index=2:3:3*N_user-1
    %     Raw_data(Queue_index,Packet_index)=random(Video_dist);
    %     end
    % end
    % BE in bits
    Packet_BE=500;
    Raw_data(3:N_service_type:end,:)=Packet_BE;
    %-------------%
    Raw_data_voice=Raw_data(1:N_service_type:end,:);
    Raw_data_video=Raw_data(2:N_service_type:end,:);
    Raw_data_BE=Raw_data(3:N_service_type:end,:);
    Raw_data_slot=Raw_data_voice+Raw_data_video+Raw_data_BE;
    Raw_data_delay=zeros(N_user*N_service_type,N_packet);
    Data_slot=zeros(N_user,N_slot);
    buffer=0;
    delay_voice=ones(N_user,N_packet)*U_voice;
    delay_video=ones(N_user,N_packet)*U_video;
    delay_BE=ones(N_user,N_packet)*U_BE;
    delay_voice_buf=zeros(N_user,N_voice);
    delay_video_buf=zeros(N_user,N_video);
    delay_BE_buf=zeros(N_user,N_BE);
    pkt_voice=0;
    pkt_video=0;
    pkt_BE=0;
    d_voice=0;
    d_video=0;
    d_BE=0;
    pkt_voice_status=zeros(N_user,N_packet);
    pkt_video_status=zeros(N_user,N_packet);
    pkt_BE_status=zeros(N_user,N_packet);
    for Slot_current=1:N_slot
        [R_MWC_eq_user(:,:,Slot_current),R_RD_eq_user(:,:,Slot_current),R_MWC_WWF_user(:,:,Slot_current)...
            ,R_RD_WWF_user(:,:,Slot_current),Data_queue,Data_user,W_voice_packet,W_video_packet,W_BE_packet...
            ,Delay_voice_set,Delay_video_set,Delay_BE_set]...
            =PHY_PD_user_basic(Slot_current,Raw_data,B,N_sc,N_user,T_slot,N_slot,Eb_N0_dB,P_total,N_path...
            ,N_channel,G,U,QoS,N_service,user_set_index,N_service_type,N_user_set,N_user_max);
        PD_capacity_MWC_eq_slot(user_set_index,Slot_current)=sum(R_MWC_eq_user(user_set_index,:,Slot_current));
        PD_capacity_MWC_WWF_slot(user_set_index,Slot_current)=sum(R_MWC_WWF_user(user_set_index,:,Slot_current));
        
        Data_slot(:,Slot_current)=Raw_data_slot(:,2*Slot_current-1)+Raw_data_slot(:,2*Slot_current);
        
        W_voice_packet_temp=W_voice_packet;
        W_voice_packet_temp(~W_voice_packet_temp)=NaN;
        
        W_video_packet_temp=W_video_packet;
        W_video_packet_temp(~W_video_packet_temp)=NaN;
        
        W_BE_packet_temp=W_BE_packet;
        W_BE_packet_temp(~W_BE_packet_temp)=NaN;
        
%         Data(:,Slot_current)=Data_slot(:,Slot_current);
        for user_index=1:N_user
            for pkt_index=1:Slot_current*T_slot
                if pkt_voice_status(user_index,pkt_index)==1
                    if Slot_current*T_slot>U_voice
                        weight_voice_index=U_voice-(Slot_current*T_slot-pkt_index);
                        if weight_voice_index>0
                            W_voice_packet_temp(user_index,weight_voice_index)=NaN;
                        end
                    else
                        weight_voice_index=pkt_index;
                        W_voice_packet_temp(user_index,weight_voice_index)=NaN;
                    end
                end
                if pkt_video_status(user_index,pkt_index)==1
                    if Slot_current*T_slot>U_video
                        weight_video_index=U_video-(Slot_current*T_slot-pkt_index);
                        if weight_video_index>0
                            W_video_packet_temp(user_index,weight_video_index)=NaN;
                        end
                    else
                        weight_video_index=pkt_index;
                        W_video_packet_temp(user_index,weight_video_index)=NaN;
                    end
                end
                if pkt_BE_status(user_index,pkt_index)==1
                    if Slot_current*T_slot>U_BE
                        weight_BE_index=U_BE-(Slot_current*T_slot-pkt_index);
                        if weight_BE_index>0
                            W_BE_packet_temp(user_index,weight_BE_index)=NaN;
                        end
                    else
                        weight_BE_index=pkt_index;
                        W_BE_packet_temp(user_index,weight_BE_index)=NaN;
                    end
                end
            end
        end
        for user_index=1:N_user
            for pkt_index=1:Slot_current*T_slot
                if pkt_voice_status(user_index,pkt_index)==0 && Slot_current*T_slot-pkt_index>=U_voice
                    pkt_voice_status(user_index,pkt_index)=NaN;
                    buffer(user_index)=buffer(user_index)-Raw_data((user_index-1)*N_service_type+1,pkt_index);
                end
                if pkt_video_status(user_index,pkt_index)==0 && Slot_current*T_slot-pkt_index>=U_video
                    pkt_video_status(user_index,pkt_index)=NaN;
                    buffer(user_index)=buffer(user_index)-Raw_data((user_index-1)*N_service_type+2,pkt_index);
                end
                if pkt_BE_status(user_index,pkt_index)==0 && Slot_current*T_slot-pkt_index>=U_BE
                    pkt_BE_status(user_index,pkt_index)=NaN;
                    buffer(user_index)=buffer(user_index)-Raw_data((user_index-1)*N_service_type+3,pkt_index);
                end
            end
        end
        buffer=buffer+Data_slot(:,Slot_current);
        capability=(T_slot*1e-3)*R_MWC_WWF_user(user_set_index,:,Slot_current)';
%         flag=buffer-capability;
        throughput_user=zeros(1,N_user);
        for user_index=1:N_user
            data_pkt_temp=0;
            throughput_temp=0;
            Weight_max=0;
            while (R_MWC_WWF_user(user_set_index,user_index,Slot_current)>B*throughput_temp)
                [Weight_voice_max,voice_max_index]=max(W_voice_packet_temp(user_index,:),[],2);
                [Weight_video_max,video_max_index]=max(W_video_packet_temp(user_index,:),[],2);
                [Weight_BE_max,BE_max_index]=max(W_BE_packet_temp(user_index,:),[],2);
                Weight_max=max([Weight_voice_max,Weight_video_max,Weight_BE_max]);
                if isnan(Weight_max)
                    break;
                end
                if Weight_max==Weight_voice_max
                    pkt_index=voice_max_index;
                    voice_index=Slot_current*T_slot-(min(N_voice,Slot_current*T_slot)-pkt_index);
                    data_pkt_temp=data_pkt_temp+Raw_data((user_index-1)*N_service_type+1,voice_index);
                    throughput_temp=data_pkt_temp/(B*T_slot*1e-3);
                    if R_MWC_WWF_user(user_set_index,user_index,Slot_current)>B*throughput_temp
                        pkt_voice_status(user_index,voice_index)=1;
                        W_voice_packet_temp(user_index,pkt_index)=NaN;
                        delay_voice(user_index,voice_index)=Delay_voice_set(user_index,pkt_index);
                        pkt_voice=pkt_voice+1;
                        d_voice=d_voice+Delay_voice_set(user_index,pkt_index);
                        buffer(user_index)=buffer(user_index)-Raw_data((user_index-1)*N_service_type+1,voice_index);
                        throughput_user(user_index)=throughput_temp;
                    end
                elseif Weight_max==Weight_video_max
                    pkt_index=video_max_index;
                    video_index=Slot_current*T_slot-(min(N_video,Slot_current*T_slot)-pkt_index);
                    data_pkt_temp=data_pkt_temp+Raw_data((user_index-1)*N_service_type+2,video_index);
                    throughput_temp=data_pkt_temp/(B*T_slot*1e-3);
                    if R_MWC_WWF_user(user_set_index,user_index,Slot_current)>B*throughput_temp
                        pkt_video_status(user_index,video_index)=1;
                        W_video_packet_temp(user_index,pkt_index)=NaN;
                        delay_video(user_index,video_index)=Delay_video_set(user_index,pkt_index);
                        pkt_video=pkt_video+1;
                        d_video=d_video+Delay_video_set(user_index,pkt_index);
                        buffer(user_index)=buffer(user_index)-Raw_data((user_index-1)*N_service_type+2,video_index);
                        throughput_user(user_index)=throughput_temp;
                    end
                elseif Weight_max==Weight_BE_max
                    pkt_index=BE_max_index;
                    BE_index=Slot_current*T_slot-(min(N_BE,Slot_current*T_slot)-pkt_index);
                    data_pkt_temp=data_pkt_temp+Raw_data((user_index-1)*N_service_type+3,BE_index);
                    throughput_temp=data_pkt_temp/(B*T_slot*1e-3);
                    if R_MWC_WWF_user(user_set_index,user_index,Slot_current)>B*throughput_temp
                        pkt_BE_status(user_index,BE_index)=1;
                        W_BE_packet_temp(user_index,pkt_index)=NaN;
                        delay_BE(user_index,BE_index)=Delay_BE_set(user_index,pkt_index);
                        pkt_BE=pkt_BE+1;
                        d_BE=d_BE+Delay_BE_set(user_index,pkt_index);
                        buffer(user_index)=buffer(user_index)-Raw_data((user_index-1)*N_service_type+3,BE_index);
                        throughput_user(user_index)=throughput_temp;
                    end
                end
            end
        end
        
        PD_throughput_slot(user_set_index,Slot_current)=sum(throughput_user);
        %                     delay_voice_temp=~pkt_voice_status*T_slot;
        %                     delay_voice_temp(:,Slot_current*T_slot+1:N_voice)=0;
        %                     delay_voice_buf=delay_voice_buf+delay_voice_temp;
        %                     delay_video_temp=~pkt_video_status*T_slot;
        %                     delay_video_temp(:,Slot_current*T_slot+1:N_video)=0;
        %                     delay_video_buf=delay_video_buf+delay_video_temp;
        %                     delay_BE_temp=~pkt_BE_status*T_slot;
        %                     delay_BE_temp(:,Slot_current*T_slot+1:N_BE)=0;
        %                     delay_BE_buf=delay_BE_buf+delay_BE_temp;
        
        %         delay_voice(~pkt_voice_status)=delay_voice(~pkt_voice_status)+T_slot;
        %         delay_voice(:,Slot_current*T_slot+1:U_voice)=0;
        %         delay_video(~pkt_video_status)=delay_video(~pkt_video_status)+T_slot;
        %         delay_video(:,Slot_current*T_slot+1:U_video)=0;
        %         delay_BE(~pkt_BE_status)=delay_BE(~pkt_BE_status)+T_slot;
        %         delay_BE(:,Slot_current*T_slot+1:U_BE)=0;
        
    end
    %     delay_voice_slot(isnan(delay_voice_slot))=U_voice;
    %     delay_video_slot(isnan(delay_video_slot))=U_video;
    %     delay_BE_slot(isnan(delay_BE_slot))=U_BE;
    
    %     delay_voice_temp=delay_voice;
    %     delay_voice_temp(delay_voice_temp==U_voice)=0;
    %     delay_voice_pos=find(delay_voice_temp(:)~=0);
    %     pkt_voice_final=length(delay_voice_pos);
    %     PD_delay_voice_avg(Eb_N0_index)=sum(delay_voice_temp(:))/pkt_voice_final;
    %
    %     delay_video_temp=delay_video;
    %     delay_video_temp(delay_video_temp==U_video)=0;
    %     delay_video_pos=find(delay_video_temp(:)~=0);
    %     pkt_video_final=length(delay_video_pos);
    %     PD_delay_video_avg(Eb_N0_index)=sum(delay_video_temp(:))/pkt_video_final;
    %
    %     delay_BE_temp=delay_BE;
    %     delay_BE_temp(delay_BE_temp==U_BE)=0;
    %     delay_BE_pos=find(delay_BE_temp(:)~=0);
    %     pkt_BE_final=length(delay_BE_pos);
    %     PD_delay_BE_avg(Eb_N0_index)=sum(delay_BE_temp(:))/pkt_BE_final;
    
    %         delay_voice_avg(Eb_N0_index)=delay_voice_avg(Eb_N0_index)+sum(sum(delay_voice(:,1:N_packet-U_voice)))/(N_packet-U_voice)/N_user;
    %         delay_video_avg(Eb_N0_index)=delay_video_avg(Eb_N0_index)+sum(sum(delay_video(:,1:N_packet-U_video)))/(N_packet-U_video)/N_user;
    %         delay_BE_avg(Eb_N0_index)=delay_BE_avg(Eb_N0_index)+sum(sum(delay_BE(:,1:N_packet-U_BE)))/(N_packet-U_BE)/N_user;
    
    %     delay_voice_avg(Eb_N0_index)=delay_voice_sum(Eb_N0_index)/N_user;
    %     delay_video_avg(Eb_N0_index)=delay_video_sum(Eb_N0_index)/N_user;
    %     delay_BE_avg(Eb_N0_index)=delay_BE_sum(Eb_N0_index)/N_user;
    
    %      delay_voice_avg(Eb_N0_index)=mean(delay_voice_slot(:));
    %      delay_video_avg(Eb_N0_index)=mean(delay_video_slot(:));
    %      delay_BE_avg(Eb_N0_index)=mean(delay_BE_slot(:));
    %      throughput(Eb_N0_index)=mean(throughput_slot(Eb_N0_index,:));
    
    %     delay_voice_avg(Eb_N0_index)=d_voice/pkt_voice;
    %     delay_video_avg(Eb_N0_index)=d_video/pkt_video;
    %     delay_BE_avg(Eb_N0_index)=d_BE/pkt_BE;
    
    delay_voice_buffer=delay_voice(:,1:N_slot*T_slot-U_voice);
    PD_delay_voice_avg(user_set_index)=sum(delay_voice_buffer(:))/(N_slot*T_slot-U_voice)/N_user;
    pkt_drop_voice=length(find(delay_voice_buffer(:)==U_voice));
    PD_pkt_drop_rate_voice(user_set_index)=pkt_drop_voice/numel(delay_voice_buffer);
    
    delay_video_buffer=delay_video(:,1:N_slot*T_slot-U_video);
    PD_delay_video_avg(user_set_index)=sum(delay_video_buffer(:))/(N_slot*T_slot-U_video)/N_user;
    pkt_drop_video=length(find(delay_video_buffer(:)==U_video));
    PD_pkt_drop_rate_video(user_set_index)=pkt_drop_video/numel(delay_video_buffer);
    
    delay_BE_buffer=delay_BE(:,1:N_slot*T_slot-U_BE);
    PD_delay_BE_avg(user_set_index)=sum(delay_BE_buffer(:))/(N_slot*T_slot-U_BE)/N_user;
    %     pkt_drop_BE_pos=find(delay_BE_buffer(:)==U_BE);
    pkt_drop_BE=length(find(delay_BE_buffer(:)==U_BE));
    PD_pkt_drop_rate_BE(user_set_index)=pkt_drop_BE/numel(delay_BE_buffer);
    
    PD_throughput(user_set_index)=mean(PD_throughput_slot(user_set_index,:));
    PD_capacity_MWC_eq(user_set_index)=mean(PD_capacity_MWC_eq_slot(user_set_index,:));
    PD_capacity_MWC_WWF(user_set_index)=mean(PD_capacity_MWC_WWF_slot(user_set_index,:));
    
    % Outage probability
    delay_voice_temp=reshape(delay_voice_buffer,1,numel(delay_voice_buffer));
    delay_video_temp=reshape(delay_video_buffer,1,numel(delay_video_buffer));
    delay_BE_temp=reshape(delay_BE_buffer,1,numel(delay_BE_buffer));
    % % %     cdfplot(delay_voice_temp);
    % %     [ycdf,xcdf] = cdfcalc(delay_voice_temp);
    % %     xccdf = xcdf;
    % %     yccdf = 1-ycdf(1:end-1);
    % %     plot(xcdf,yccdf);
    %     plot(sort(delay_voice_temp), linspace(1-1/length(delay_voice_temp), 0, length(delay_voice_temp)))
end
testflag=1;

save PD_user_basic.mat Eb_N0_dB PD_delay_voice_avg PD_delay_video_avg PD_delay_BE_avg...
    PD_pkt_drop_rate_voice PD_pkt_drop_rate_video PD_pkt_drop_rate_BE...
    PD_throughput user_set