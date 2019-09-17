function [R_MWC_eq_user,R_RD_eq_user,R_MWC_WWF_user,R_RD_WWF_user,Data_queue,Data_user,...
    W_voice_packet,W_video_packet,W_BE_packet,Delay_voice_set,Delay_video_set,Delay_BE_set]...
    =PHY_PD_user_basic(Slot_current,Raw_data,B,N_sc,N_user,T_slot,N_slot,user_set_dB,P_total,N_path,N_channel,G,U,QoS,N_service...
    ,user_set_index,N_service_type,N_user_set,N_user_max)

N0=P_total*(T_slot*1e-3/N_sc)./10.^(user_set_dB/10);
%Scale to achieve unit power for each channel
norm_scale=sqrt(1/(2*N_path));
%matrix to hold subcarrier allocation results
%result1->maximum gain for each subcarriers in 1000 channels
MWC_result1=zeros(N_channel,N_sc);
RD_result1=zeros(N_channel,N_sc);
%result2->subcarriers and corresponding users
MWC_result2=zeros(N_channel,N_sc);
RD_result2=zeros(N_channel,N_sc);
%initialise the number of subcarriers to be employed for each channel with
%water-filling algorithm: some of the subcarriers might be abandoned during
%iterating but the default value should be the number of all subcarriers
%only the cases for water-filling power allocation are considered since for
%equal power allocation it is assumed that all subcarriers should be used
num_MWC_WWF_sc=zeros(N_user_set,N_channel);
num_MWC_WWF_sc(:,:)=N_sc;
num_RD_WWF_sc=zeros(N_user_set,N_channel);
num_RD_WWF_sc(:,:)=N_sc;

R_MWC_eq_user=zeros(N_user_set,N_user_max);
R_RD_eq_user=zeros(N_user_set,N_user_max);
R_MWC_WWF_user=zeros(N_user_set,N_user_max);
R_RD_WWF_user=zeros(N_user_set,N_user_max);
%vary user_set to check the performance under diverse situations
% for user_set_index=1:N_user_set
%     Weight_sum_MWC=zeros(N_channel,N_user);
%     Weight_sum_RD=zeros(N_channel,N_user);
%     %convert Eb/N0 into the linear scale
%     user_set=10.^(user_set_dB_index/10);
%     %Calculate the correspnding noise power spectral density
%     N0=Eb./user_set;
Weight_sum_MWC=zeros(1,N_slot);
Weight_sum_RD=zeros(1,N_slot);
%matrices to hold invalid index
P_MWC_WWF_sc_iter=zeros(N_channel,N_sc);
P_RD_WWF_sc_iter=zeros(N_channel,N_sc);
%     % To be modified---------------------------------------------------------
%     [W_voice_packet,W_video_packet,W_BE_packet,Data,~]=scheduling_PD_ver2(Slot_current,N_user,N_slot);
%     W_voice=max(W_voice_packet,[],2);
%     W_video=max(W_video_packet,[],2);
%     W_BE=max(W_BE_packet,[],2);
%     %     % To be modified===========1000
%     %     Weight=zeros(3*N_user,N_slot);
%     %     Weight(1:3:end,:)=W_voice_packet;
%     %     Weight(2:3:end,:)=W_video_packet;
%     %     Weight(3:3:end,:)=W_BE_packet;
%     W_user=W_voice+W_video+W_BE;
%     Weight_sum_MWC(user_set_dB_index,:)=sum(W_user);
%     Weight_sum_RD(user_set_dB_index,:)=sum(W_user);
%     %generate channels and allocate resources
[W_voice_packet,W_video_packet,W_BE_packet,Data_queue,Data_user,Delay_voice_set,Delay_video_set,Delay_BE_set]=...
    MAC_PD_user_basic(Slot_current,N_user,N_slot,Raw_data,T_slot,G,U,QoS,N_service);
for user_index=1:N_user
    %         weight_PD(k,currentslot)=sum(w_Voice_PD(k,:))+sum(w_Video_PD(k,:))+sum(w_BE_PD(k,:));
    %         weight(k,currentslot)=sum(w_Voice(k,:))+sum(w_Video(k,:))+sum(w_BE(k,:));
    W_user(user_index,Slot_current)=sum(W_voice_packet(user_index,:))+sum(W_video_packet(user_index,:))+sum(W_BE_packet(user_index,:));
end

for cn_index=1:N_channel
    %create Rayleigh fading channel for users
    for user_index=1:N_user
        h(user_index,:)=norm_scale*(randn(1,N_path) + 1i*randn (1,N_path) );
        %FFT with points = number of subcarriers to analyse in
        %frequency domain
        H(user_index,:)=fft(h(user_index,:),N_sc);
    end
    %subcarrier allocation: random allocation and maximum capacity
    %allocation based on the maximum gain for users
    %         for user_index=1:N_user
    H_abs_RD=abs(H);
    for sc_index=1:N_sc
        user_current=mod(sc_index-1,N_user)+1;
        %random subcarrier allocation
        %result 1 holds gains for each subcarrier
        RD_result1(cn_index,sc_index)=H_abs_RD(user_current,sc_index);
        %result 2 holds the allocation result: subcarriers are
        %distributed to users with corresponding indexes (eg.
        %subcarrier 1->user 1, etc.)
        RD_result2(cn_index,sc_index)=user_current;
        %Power of subchannels for random subcarrier allocation
        P_RD_eq_sc(cn_index,sc_index)=(P_total/N_sc)*RD_result1(cn_index,sc_index)^2;
        %remove the allocated user by setting other subcarriers' gains for this user to 0
        H_abs_RD(:,sc_index)=0;
    end
    %         end
    H_abs_MWC=abs(H);
    for sc_index=1:N_sc
        %The weighted gain
        H_weighted_abs=repmat(W_user(:,Slot_current),1,N_sc).*H_abs_MWC;
        %MWSC subcarrier allocation
        %store the maximum gain for each subcarrier and corresponding user
        %index (user index->MC_index)
        [~,MWC_index]=max(H_weighted_abs(:,sc_index),[],1);
        %result 2 holds the subchannel allocation result(users->subcarriers)
        MWC_result2(cn_index,sc_index)=MWC_index;
        %result 1 holds gains for each subchannel
        %MWC_result1(cn_index,sc_index)=MWC_weighted_gain/W_user(MWC_index);
        MWC_result1(cn_index,sc_index)=H_abs_MWC(MWC_index,sc_index);
        %remove the allocated user by setting other subcarriers' gains for this user to 0
        H_abs_MWC(:,sc_index)=0;
        %Power of subchannels for MWC allocation
        P_MWC_eq_sc(cn_index,sc_index)=(P_total/N_sc)*MWC_result1(cn_index,sc_index)^2;
    end
    for sc_index=1:N_sc
        Weight_sum_MWC(Slot_current)=Weight_sum_MWC(Slot_current)+W_user(MWC_result2(cn_index,sc_index),Slot_current);
        Weight_sum_RD(Slot_current)=Weight_sum_RD(Slot_current)+W_user(MWC_result2(cn_index,sc_index),Slot_current);
    end
    %calculate parameter gamma (gamma->r) in suboptimal solution
    chh=abs(H).^2;
    noise=N0*B/N_sc;
    CNR=chh/noise;
    for sc_index=1:N_sc
        r_MWC(cn_index,sc_index)= MWC_result1(cn_index,sc_index)^2/((N0*B)/N_sc);
        r_RD(cn_index,sc_index)= RD_result1(cn_index,sc_index)^2/((N0*B)/N_sc);
        %reciprocate of r
        rec_r_MWC(cn_index,sc_index)=1/r_MWC(cn_index,sc_index);
        rec_r_RD(cn_index,sc_index)=1/r_RD(cn_index,sc_index);
    end
    %flag to indicate the number of subchannels with invalid power
    %allocated by water-filling algorithm: 0->all subcarriers are
    %acceptable and no further iteration is needed; non-zero
    %value->the corresponding subchannels should be abandoned and
    %the others should be reallocated
    %initialise flag to begin water-filling algorithm: the initial value is
    %actually meaningless only to switch on water-filling algorithm
    flag_MWC_WWF_sc=N_sc;
    flag_RD_WWF_sc=N_sc;
    flag_MWC_removed=zeros(1,N_sc);
    flag_RD_removed=zeros(1,N_sc);
    %if flag is non-zero value, the channel should be iterated
    while(flag_MWC_WWF_sc~=0)||(flag_RD_WWF_sc~=0)
        %assume that all subcarriers are valid in the beginning
        flag_MWC_WWF_sc=0;
        flag_RD_WWF_sc=0;
        %for each subcarrier, check whether the flag state is
        %invalid: if so, removing it from the queue by allocating
        %no power to it and set the reciprocate of gamma to 0
        for sc_index=1:N_sc
            if P_MWC_WWF_sc_iter(cn_index,sc_index)==1
                P_MWC_WWF_sc(cn_index,sc_index)=0;
                rec_r_MWC(cn_index,sc_index)=0;
            end
            if P_RD_WWF_sc_iter(cn_index,sc_index)==1
                P_RD_WWF_sc(cn_index,sc_index)=0;
                rec_r_RD(cn_index,sc_index)=0;
            end
        end
        %then reallocate power to the other subchannels with
        %updated gamma set and number of available subcarriers
        for sc_index=1:N_sc
            %if the subchannel is valid (have not been allocated
            %with 0 or negative power)
            if P_MWC_WWF_sc_iter(cn_index,sc_index)==0
                %suboptimal solution only suitable for positive power
                %P_MC_WF_sc(cn_index,sc_index)=((P_total+sum(rec_r_MWC(cn_index,:)))/num_MC_WF_sc(user_set_dB_index,cn_index))-rec_r_MWC(cn_index,sc_index);
                %P_MWC_WWF_sc(cn_index,sc_index)=(W_user(MWC_result2(cn_index,sc_index))/sum(W_user)/num_MWC_WWF_sc(user_set_dB_index,cn_index)).*(P_total+sum(rec_r_MWC(cn_index,:)))-rec_r_MWC(cn_index,sc_index);
                P_MWC_WWF_sc(cn_index,sc_index)=W_user(MWC_result2(cn_index,sc_index),Slot_current)...
                    *(P_total+sum(rec_r_MWC(cn_index,:)))/Weight_sum_MWC(Slot_current)-rec_r_MWC(cn_index,sc_index);
                %P_MWC_WWF_sc(cn_index,sc_index)=((P_total+sum(rec_r_MWC(cn_index,:)))/num_MWC_WWF_sc(user_set_dB_index,cn_index))-rec_r_MWC(cn_index,sc_index);
            end
            %                 PA(pos(t))=(Pt+sum(1./Newindex_CNR))*W(k,currentslot)/sumW-1/index_CNR(pos(t));
            if P_RD_WWF_sc_iter(cn_index,sc_index)==0
                %P_RD_WWF_sc(cn_index,sc_index)=((P_total+sum(rec_r_RD(cn_index,:)))/num_RD_WWF_sc(user_set_dB_index,cn_index))-rec_r_RD(cn_index,sc_index);
                P_RD_WWF_sc(cn_index,sc_index)=W_user(RD_result2(cn_index,sc_index),Slot_current)...
                    *(P_total+sum(rec_r_RD(cn_index,:)))/Weight_sum_RD(Slot_current)-rec_r_RD(cn_index,sc_index);
            end
            %for non-positive power cases, we need to iterate
            %and overwrite existing subchannels
            %the 'and' operation is to make sure that 0 power is
            %derived by suboptimal solution, rather than manually
            if (P_MWC_WWF_sc(cn_index,sc_index)<=0)&&(rec_r_MWC(cn_index,sc_index)~=0)
                %set correspinding iter state to 1 for further iteration
                P_MWC_WWF_sc_iter(cn_index,sc_index)=1;
                %number of bad subchannel +1
                flag_MWC_WWF_sc=flag_MWC_WWF_sc+1;
                %updates the weight set
                %Weight_sum_MWC(user_set_dB_index,cn_index)=Weight_sum_MWC(user_set_dB_index,cn_index)-
            end
            if (P_RD_WWF_sc(cn_index,sc_index)<=0)&&(rec_r_RD(cn_index,sc_index)~=0)
                P_RD_WWF_sc_iter(cn_index,sc_index)=1;
                flag_RD_WWF_sc=flag_RD_WWF_sc+1;
            end
        end
        %update the available subchannels
        num_MWC_WWF_sc(user_set_index,cn_index)=num_MWC_WWF_sc(user_set_index,cn_index)-flag_MWC_WWF_sc;
        num_RD_WWF_sc(user_set_index,cn_index)=num_RD_WWF_sc(user_set_index,cn_index)-flag_RD_WWF_sc;
        if flag_MWC_WWF_sc~=0
            for bad_sc_index=1:N_sc
                if (P_MWC_WWF_sc_iter(cn_index,bad_sc_index)~=0) && (flag_MWC_removed(bad_sc_index)==0)
                    Weight_sum_MWC(Slot_current)=Weight_sum_MWC(Slot_current)-W_user(MWC_result2(cn_index,bad_sc_index),Slot_current);
                    flag_MWC_removed(bad_sc_index)=1;
                end
            end
        end
        if flag_RD_WWF_sc~=0
            for bad_sc_index=1:N_sc
                if (P_RD_WWF_sc_iter(cn_index,bad_sc_index)~=0) && (flag_RD_removed(bad_sc_index)==0)
                    Weight_sum_RD(Slot_current)=Weight_sum_RD(Slot_current)-W_user(RD_result2(cn_index,bad_sc_index),Slot_current);
                    flag_RD_removed(bad_sc_index)=1;
                end
            end
        end
    end
    
    %recheck the total transmitted power of water filling algorithm
    %(should be 1 for all channels)
    P_MWC_WWF_sum(user_set_index,cn_index)=sum(P_MWC_WWF_sc(cn_index,:));
    P_RD_WWF_sum(user_set_index,cn_index)=sum(P_RD_WWF_sc(cn_index,:));
    %calculate the channel total power for equal power allocation for
    %further normalisation
    P_MWC_eq_sum(user_set_index,cn_index)=sum(P_MWC_eq_sc(cn_index,:));
    P_RD_eq_sum(user_set_index,cn_index)=sum(P_RD_eq_sc(cn_index,:));
    %scales for normalisation
    P_MWC_eq_scale(user_set_index,cn_index)=P_total./P_MWC_eq_sum(user_set_index,cn_index);
    P_RD_eq_scale(user_set_index,cn_index)=P_total./P_RD_eq_sum(user_set_index,cn_index);
    %normalise the transmitted power
    for sc_index=1:N_sc
        P_MWC_eq_sc(cn_index,sc_index)=P_MWC_eq_sc(cn_index,sc_index).*P_MWC_eq_scale(user_set_index,cn_index);
        P_RD_eq_sc(cn_index,sc_index)=P_RD_eq_sc(cn_index,sc_index).*P_RD_eq_scale(user_set_index,cn_index);
    end
    %recheck the total transmitted power of equal power algorithm
    %(should be 1 for all channels)
    P_MWC_eq_sum_updated(user_set_index,cn_index)=sum(P_MWC_eq_sc(cn_index,:));
    P_RD_eq_sum_updated(user_set_index,cn_index)=sum(P_RD_eq_sc(cn_index,:));
end

%     index_CNR(n)=CNR(k,n);

for cn_index=1:N_channel
    %calculate data rate on subchannel bases
    for sc_index=1:N_sc
        %subcarrier data rate of random and maximum capacity subcarrier allocation & equal and water
        %filling power allocation
        %for equal power allocation, all subcarriers are employed
        %(B/N)*log2(1+PA_PD(n)*Index_CNR_PD(n))*(T*1e-3);
        R_MWC_eq_sc(cn_index,sc_index)=(B/N_sc)*log2(1+P_MWC_eq_sc(cn_index,sc_index)*r_MWC(cn_index,sc_index));
        R_RD_eq_sc(cn_index,sc_index)=(B/N_sc)*log2(1+P_RD_eq_sc(cn_index,sc_index)*r_RD(cn_index,sc_index));
        %for water-filling allocation, only valid subcarriers are
        %considered
        R_MWC_WWF_sc(cn_index,sc_index)=(B/N_sc)*log2(1+P_MWC_WWF_sc(cn_index,sc_index)*r_MWC(cn_index,sc_index));
        R_RD_WWF_sc(cn_index,sc_index)=(B/N_sc)*log2(1+P_RD_WWF_sc(cn_index,sc_index)*r_RD(cn_index,sc_index));
    end
    %channel data rate: sum of subcarrier data rate
    R_MWC_eq_cn(cn_index)=sum(R_MWC_eq_sc(cn_index,:));
    R_RD_eq_cn(cn_index)=sum(R_RD_eq_sc(cn_index,:));
    R_MWC_WWF_cn(cn_index)=sum(R_MWC_WWF_sc(cn_index,:));
    R_RD_WWF_cn(cn_index)=sum(R_RD_WWF_sc(cn_index,:));
    for sc_index=1:N_sc
        %Data rate of users at slots
        R_MWC_eq_temp(user_set_index,sc_index)=mean(R_MWC_eq_sc(:,sc_index));
        R_RD_eq_temp(user_set_index,sc_index)=mean(R_RD_eq_sc(:,sc_index));
        R_MWC_WWF_temp(user_set_index,sc_index)=mean(R_MWC_WWF_sc(:,sc_index));
        R_RD_WWF_temp(user_set_index,sc_index)=mean(R_RD_WWF_sc(:,sc_index));
    end
    for sc_index=1:N_sc
        R_MWC_eq_user(user_set_index,MWC_result2(cn_index,sc_index))=R_MWC_eq_user(user_set_index,MWC_result2(cn_index,sc_index))+R_MWC_eq_temp(user_set_index,sc_index);
        R_RD_eq_user(user_set_index,RD_result2(cn_index,sc_index))=R_RD_eq_user(user_set_index,MWC_result2(cn_index,sc_index))+R_RD_eq_temp(user_set_index,sc_index);
        R_MWC_WWF_user(user_set_index,MWC_result2(cn_index,sc_index))=R_MWC_WWF_user(user_set_index,MWC_result2(cn_index,sc_index))+R_MWC_WWF_temp(user_set_index,sc_index);
        R_RD_WWF_user(user_set_index,RD_result2(cn_index,sc_index))=R_RD_WWF_user(user_set_index,MWC_result2(cn_index,sc_index))+R_RD_WWF_temp(user_set_index,sc_index);
    end
    %     end
    %average channel data rates
    %     R_MWC_eq_slot(user_set_dB_index,1)=mean(R_MWC_eq_cn(:));
    %     R_RD_eq_slot(user_set_dB_index,1)=mean(R_RD_eq_cn(:));
    %     R_MWC_WWF_slot(user_set_dB_index,1)=mean(R_MWC_WWF_cn(:));
    %     R_RD_WWF_slot(user_set_dB_index,1)=mean(R_RD_WWF_cn(:));
    %Data rate of users at slots
    
end

% figure;
% plot(R_MWC_eq_avg_SNR);
% hold on;
% plot(R_RD_eq_avg_SNR);
% hold on;
% plot(R_MWC_WWF_avg_SNR);
% hold on;
% plot(R_RD_WWF_avg_SNR);
% title('Eb/N0 vs. Channel Data Rate for MWC and Random & Equal and WWF Resource Allocation');
% xlabel('Eb/N0 (dB)');
% ylabel('Channel Data Rate');
% legend('MWC + EQ','RD + EQ','MWC + WWF','RD + WWF','location','NorthWest');
% grid on;
% set(gca,'FontSize',24);
end
