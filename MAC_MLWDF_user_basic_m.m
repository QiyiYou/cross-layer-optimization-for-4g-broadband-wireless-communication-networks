 %% M-LWDF Scheduling (queue based)
 
function [Data_MLWDF, Weight_MLWDF]=MAC_MLWDF_user_basic_m(Slot_current,Raw_data,Data_MLWDF,Weight_MLWDF,N_user,U,capacity_avg,T_slot,Delta,N_service_type)
% Current time
T_current=Slot_current*T_slot;
% Delta set
Delta_voice=Delta(1);
Delta_video=Delta(2);
Delta_BE=Delta(3);
% Delay tolerance set
U_voice=U(1);
U_video=U(2);
U_BE=U(3);
%% Voice queue:
for user_index=1:N_user
    if T_current<=U_voice
        for T_packet=1:T_current
            if Raw_data((user_index-1)*N_service_type+1, T_packet)>0 
                break; 
            end
        end     
        Data_MLWDF((user_index-1)*N_service_type+1, Slot_current)=Data_MLWDF(N_service_type*(user_index-1)+1, Slot_current)+sum(Raw_data(N_service_type*(user_index-1)+1,1:T_current));
    else        
        for T_packet=T_current+1-U_voice:T_current
            if Raw_data((user_index-1)*N_service_type+1, T_packet)>0 
                break; 
            end
        end
        Data_MLWDF((user_index-1)*N_service_type+1, Slot_current)=Data_MLWDF(N_service_type*(user_index-1)+1, Slot_current)+sum(Raw_data(N_service_type*(user_index-1)+1,T_current+1-U_voice:T_current));
    end
     Weight_MLWDF((user_index-1)*N_service_type+1,Slot_current)=-log10(Delta_voice)*(T_current-T_packet+1)/capacity_avg((user_index-1)*N_service_type+1)*T_slot/U_voice;
end
 %% Video queue:
for user_index=1:N_user
    if T_current<=U_video
        for T_packet=1:T_current
            if Raw_data((user_index-1)*N_service_type+2, T_packet)>0 
                break; 
            end
        end
        Data_MLWDF((user_index-1)*N_service_type+2, Slot_current)=Data_MLWDF(N_service_type*(user_index-1)+2, Slot_current)+sum(Raw_data(N_service_type*(user_index-1)+2,1:T_current));
    else 
        for T_packet=T_current+1-U_video:T_current
            if Raw_data((user_index-1)*N_service_type+2, T_packet)>0  
                break;
            end
        end       
        Data_MLWDF((user_index-1)*N_service_type+2, Slot_current)=Data_MLWDF(N_service_type*(user_index-1)+2, Slot_current)+sum(Raw_data(N_service_type*(user_index-1)+2,T_current+1-U_video:T_current));
    end
     Weight_MLWDF((user_index-1)*N_service_type+2,Slot_current)=-log10(Delta_video)*(T_current-T_packet+1)/capacity_avg((user_index-1)*N_service_type+2)*T_slot/U_video;  
end
 %% BE queue:
for user_index=1:N_user
    if T_current<=U_BE
        for T_packet=1:T_current
            if Raw_data((user_index-1)*N_service_type+3, T_packet)>0 
                break; 
            end
        end
        Data_MLWDF((user_index-1)*N_service_type+3, Slot_current)=Data_MLWDF(N_service_type*(user_index-1)+3, Slot_current)+sum(Raw_data(N_service_type*(user_index-1)+3,1:T_current));
    else       
        for T_packet=T_current+1-U_BE:T_current
            if Raw_data((user_index-1)*N_service_type+3, T_packet)>0 
                break; 
            end
        end       
        Data_MLWDF((user_index-1)*N_service_type+3, Slot_current)=Data_MLWDF(N_service_type*(user_index-1)+3, Slot_current)+sum(Raw_data(N_service_type*(user_index-1)+3,T_current+1-U_BE:T_current));
    end
    Weight_MLWDF((user_index-1)*N_service_type+3,Slot_current)=-log10(Delta_BE)*(T_current-T_packet+1)/capacity_avg((user_index-1)*N_service_type+3)*T_slot/U_BE;
end