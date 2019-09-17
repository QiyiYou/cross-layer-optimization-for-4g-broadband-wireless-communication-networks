 %% M-LWDF Scheduling (queue based)
 
function [Data_MLWDF, Weight_MLWDF]=MAC_MLWDF_user_basic(Slot_current,Raw_data,Data_MLWDF,Weight_MLWDF,N_user,U,capacity_avg,T_slot,Delta)
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
% a1=-log10(0.05)/(U(1)*1e-3);
% a2=-log10(0.05)/(U(2)*1e-3);
% a3=-log10(0.77)/(U(3)*1e-3);
% %a3=0.26;
%% For Queue1: Voice
for user_index=1:N_user
    if T_current<=U_voice        
        for T_packet=1:T_current
            if Raw_data((user_index-1)*length(U)+1, T_packet)>0 
                break; 
            end
        end     
        Data_MLWDF((user_index-1)*length(U)+1, Slot_current)=Data_MLWDF(length(U)*(user_index-1)+1, Slot_current)+sum(Raw_data(length(U)*(user_index-1)+1,1:T_current));
    else        
        for T_packet=T_current+1-U_voice:T_current
            if Raw_data((user_index-1)*length(U)+1, T_packet)>0 
                break; 
            end
        end
        Data_MLWDF((user_index-1)*length(U)+1, Slot_current)=Data_MLWDF(length(U)*(user_index-1)+1, Slot_current)+sum(Raw_data(length(U)*(user_index-1)+1,T_current+1-U_voice:T_current));
    end
     Weight_MLWDF((user_index-1)*length(U)+1,Slot_current)=-log10(Delta_voice)*(T_current-T_packet+1)/capacity_avg((user_index-1)*length(U)+1)*T_slot/U_voice;
end
 %% For Queue 2: Video
for user_index=1:N_user
    if T_current<=U_video        
        for T_packet=1:T_current
            if Raw_data((user_index-1)*length(U)+2, T_packet)>0 
                break; 
            end
        end
        Data_MLWDF((user_index-1)*length(U)+2, Slot_current)=Data_MLWDF(length(U)*(user_index-1)+2, Slot_current)+sum(Raw_data(length(U)*(user_index-1)+2,1:T_current));
    else 
        for T_packet=T_current+1-U_video:T_current
            if Raw_data((user_index-1)*length(U)+2, T_packet)>0  
                break;
            end
        end       
        Data_MLWDF((user_index-1)*length(U)+2, Slot_current)=Data_MLWDF(length(U)*(user_index-1)+2, Slot_current)+sum(Raw_data(length(U)*(user_index-1)+2,T_current+1-U_video:T_current));
    end
     Weight_MLWDF((user_index-1)*length(U)+2,Slot_current)=-log10(Delta_video)*(T_current-T_packet+1)/capacity_avg((user_index-1)*length(U)+2)*T_slot/U_video;  
end
 %% For Queue 3: BE
for user_index=1:N_user
    if T_current<=U_BE        
        for T_packet=1:T_current
            if Raw_data((user_index-1)*length(U)+3, T_packet)>0 
                break; 
            end
        end
        Data_MLWDF((user_index-1)*length(U)+3, Slot_current)=Data_MLWDF(length(U)*(user_index-1)+3, Slot_current)+sum(Raw_data(length(U)*(user_index-1)+3,1:T_current));
    else       
        for T_packet=T_current+1-U_BE:T_current
            if Raw_data((user_index-1)*length(U)+3, T_packet)>0 
                break; 
            end
        end       
        Data_MLWDF((user_index-1)*length(U)+3, Slot_current)=Data_MLWDF(length(U)*(user_index-1)+3, Slot_current)+sum(Raw_data(length(U)*(user_index-1)+3,T_current+1-U_BE:T_current));
    end
    Weight_MLWDF((user_index-1)*length(U)+3,Slot_current)=-log10(Delta_BE)*(T_current-T_packet+1)/capacity_avg((user_index-1)*length(U)+3)*T_slot/U_BE;
end
testflag=1;