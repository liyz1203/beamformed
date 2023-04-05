F_number=2; %焦圈数
P.startDepth = 1;  % Define startDepth and endDepth at top for use in defining other parameters.
P.endDepth = 101;
P.numRays = 128; % 每一帧发射的线数
Resource.Parameters.speedOfSound = 1540;
Receive(1).decimSampleRate=125e6; %采样频率125MHz
sample_space=Resource.Parameters.speedOfSound/Receive(1).decimSampleRate; % 采样间隔

rcvData = load('RcvData.mat'); %819200×128×20 总数；通道数；发射数
RcvData = rcvData.RcvData;

receive = load('Receive.mat');
Receive = receive.Receive;

tx = load('TX.mat');
TX = tx.TX;

txorgx = load('TxOrgX.mat');
TxOrgX = txorgx.TxOrgX;

trans = load('Trans.mat');
Trans = trans.Trans;

ChannelData=cell2mat(RcvData);
channelData(:,:)=ChannelData(:,:,1);
[totalPoints,numChannel]=size(channelData);

Ori_RayData=[];
Transmit_aperture=[];
Transmit_Delay=[];
Transmit_Apod=[];

   for hi=1:P.numRays 
         Ori_RayData=channelData(Receive(hi*2-1).startSample+1:Receive(hi*2).endSample,:);
         Transmit_aperture=find(TX(hi).Apod>0); %激发
         Transmit_Delay=TX(hi).Delay(Transmit_aperture);%以波长为单位的时间，发射延迟时间
         Transmit_Apod=TX(hi).Apod(Transmit_aperture);
         RayData=Ori_RayData(:,Transmit_aperture); % 获取channelData中该发射线的接收数据。
         %？？？sampleDepth(hi)=(Receive(hi*2-1).endDepth-Receive(hi*2-1).startDepth)*Receive(hi*2-1).samplesPerWave*2;
         sampleDepth(hi)=(Receive(hi*2-1).endDepth-Receive(hi*2-1).startDepth)*Receive(hi*2-1).samplesPerWave*2;%该线对应的采样深度
         
         for di=1:sampleDepth(hi) % 遍历该线的每一个接收元件
             line=[];
              for pi=1:length(Transmit_aperture)
                  posi_Ray=TX(hi).Origin;
                  num_xdirection(pi)=posi_Ray(1)-TxOrgX((Transmit_aperture(pi)));
                  length_xdirection(pi)=num_xdirection(pi)*Receive(hi*2-1).samplesPerWave;
                  %？？？？
                  line(pi)=round(sqrt((di).^2+length_xdirection(pi).^2)*2);
                  %line(pi) = round(sample_space/125e6)*length_xdirection(pi);
%                   if line(pi) < 1
%                       line_point(pi) = 0;
%                   else
%                       line_point(pi) = RayData(line(pi),pi);
%                   end

                  if line(pi)>3071
                      line_point(pi)=0;
                  else
                      line_point(pi)=RayData(line(pi),pi);
                  end
              end
              %？？？不需要/2
              half_aperture=ceil( (di*sample_space)/F_number/Trans.spacing/2);% Trans.spacing 阵元的宽度 % element spacing in wavelengths
              if half_aperture*2>=length(Transmit_aperture) %???平方
                  RFData(di,hi)=sum(line_point);
              else
                  wa=find(Transmit_Apod==max(Transmit_Apod));
                  RFData(di,hi)=sum(line_point(wa-half_aperture:wa+half_aperture));
              end
         end
   end

figure()
colormap(gray(128));
brighten(-0.5);
%imagesc(10*log10(abs( double(P.startDepth*RFData(Receive(hi*2-1).samplesPerWave*2:P.endDepth*Receive(hi*2-1).samplesPerWave*2,:)) )))
%冒号运算需取整
imagesc(10*log10(abs( double(P.startDepth*RFData(round(Receive(hi*2-1).samplesPerWave*2):round(P.endDepth*Receive(hi*2-1).samplesPerWave*2),:)) )))
ylabel('Samples'); xlabel('Scan Lines');


