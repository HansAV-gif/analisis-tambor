%% ANALISIS DE AVALANCHA DE PARTICULAS NO CONVEXAS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Establecer LaTeX como el intérprete predeterminado
%set(groot, 'DefaultTextInterpreter', 'latex');
set(groot, 'DefaultLegendInterpreter', 'latex');
%set(groot, 'DefaultAxesTickLabelInterpreter', 'latex');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc,close all

% ¿GRAFICO? 1=si 0=no
grafica=1;

% ORDENO ARCHIVOS TEMPORALMENTE
files = dir('*.jpg');  % Asume que los archivos son JPEG
[~, idx] = sort([files.datenum]);  % Ordena los archivos por fecha
files = files(idx);  % Reordena la estructura de archivos

% ACA SE DEBE AGREGAR EL CODIGO PARA OBTENER EL TIEMPO

%leer imagen
% OJO CON EL FLIP. PARA IMAGENES CON EL MOTOR NUEVO NO SE VA A NECESITAR
Img = flip(imread(files(1).name),2);
num_imagenes = length(files);
% Tamaño y numero de imagenes
[Lx, Ly]= size(Img);

% Definir la nueva posición del punto de referencia
x0 = 734; % Nueva coordenada x del punto de referencia
y0 = 1423; % Nueva coordenada y del punto de referencia
centro=[x0 y0];

% OJO, SE DEBE REDIFINIR PARA EL MOTOR NUEVO
escala=0.02;% factor de conversion cm/px
Largo_x = (linspace(0,Lx)*escala)-(x0*escala);
Largo_y = (linspace(0,Ly)*escala)-(y0*escala);


%ajustar el origen en cm
imagesc(Img);
% SE TIENE QUE REDIFINIR A MANO CUANDO SE HACE CAMBIA EL FACTOR DE
% CONVERSION
set(gca,'Layer','top','XTick',...
    [0 134 234 334 434 534 634 734 834 934 1034 1134 1234 1334 1472],...
    'XTickLabel',...
    {'-14.68','-12','-10','-8','-6','-4','-2','0','2','4','6','8','10','12','14.76','','',''},...
    'YTick',[0 173 423 673 923 1173 1423],'YTickLabel',...
    {'28.46','25','20','15','10','5','0','-577','-777','-977','-1177','-1377','',''});


%Img_filtradas = zeros(Lx, Ly, num_imagenes, 'uint8');
Superficies = zeros(Ly, num_imagenes);
Pendientes = zeros(num_imagenes,1);
Area_particulas = zeros(num_imagenes,3); % particulas, grupo, resta



% Mostrar la imagen y obtener puntos del usuario
figure, imagesc(Img);
set(gca,'Layer','top','XTick',...
    [0 134 234 334 434 534 634 734 834 934 1034 1134 1234 1334 1472],...
    'XTickLabel',...
    {'-14.68','-12','-10','-8','-6','-4','-2','0','2','4','6','8','10','12','14.76','','',''},...
    'YTick',[0 173 423 673 923 1173 1423],'YTickLabel',...
    {'28.46','25','20','15','10','5','0','-577','-777','-977','-1177','-1377','',''});
title('******* SELECCIONA 4 PUNTOS DEL CONTORNO DEL DISCO *******')
hold on;
[xf, yf] = ginput(4);
plot(xf, yf, 'wo', 'MarkerFaceColor', 'auto');
hold off;

% Calcular el centro y el radio del círculo
[Radius, x_centro, y_centro] = circfit(xf, yf);

% Crear la máscara
[x, yD] = meshgrid(1:Ly, 1:Lx);
Unos = (x - x_centro).^2 + (yD - y_centro).^2 <= Radius^2;

% Aplicar la máscara a la imagen
I_new = uint8(Unos) .* Img;  % Asegurarse de que ambos son del mismo tipo de datos

% Límites del intervalo centrado en x_centro
Delta = 200;
x_centro = x_centro - 200;
limite_inferior = max(1, round(x_centro) - Delta);  % Asegurarse de que no sea menor que 1
limite_superior = min(length(Img), round(x_centro) + Delta);  % Asegurarse de que no sea mayor que la longitud del perfil

% Extraer los puntos del perfil dentro del intervalo
a_intervalo = limite_inferior:limite_superior;

%
centros_de_masa = zeros(num_imagenes, 2);

% Bucle para procesar cada imagen
for k = 1:num_imagenes

    I = uint8(Unos).* flip(imread(files(k).name),2);
    I_bw = imbinarize(I,0.3);

    % Elimina objetos conectados que tienen menos de 500 píxeles
    I_filtrada = bwareaopen(I_bw, 5000);
    particulas = sum(I_filtrada(:));

    % RELLENO IMAGEN Y CALCULO AREA TOTAL
    I_llena = imfill(I_filtrada, 'holes');
    grupo = sum(I_llena(:));
    % ESPACIOS VACIOS
    I_gap = grupo - particulas;

    % ENCUENTRO EL PERIMETRO
    I_borde = bwperim(I_filtrada);

    % Relleno areas (cm^2)
    Area_particulas(k,1) = particulas*escala^2;
    Area_particulas(k,2) = grupo*escala^2;
    Area_particulas(k,3) = I_gap*escala^2;

    % Crear un arreglo para almacenar las coordenadas del centro de masa en cada imagen
    %

    % Etiquetar las regiones conectadas en la imagen binaria
    etiquetas = bwlabel(I_filtrada);

    % Calcular propiedades de la región, incluido el centro de masa
    propiedades = regionprops(etiquetas, 'Centroid');

    % Calcular el centro de masa general para todas las partículas
    %centro_masas_totales = zeros(1, 2);
    %total_particulas = length(propiedades);

    %for j = 1:total_particulas
    %    centro_masas_totales = centro_masas_totales + propiedades(j).Centroid;
    %end

    %centro_masas_totales = centro_masas_totales / total_particulas;

    % Almacenar el centro de masa en el arreglo
    centros_de_masa(k, :) = propiedades.Centroid;

    % Mostrar o procesar los resultados según sea necesario
    %disp('Centros de masa en coordenadas (x, y):');
    %disp(centros_de_masa);

    % Encontrar objetos conectados en la imagen binarizada
    %CC = bwconncomp(I_filtrada);
    %S = regionprops('table',CC,'Perimeter','Area');

    % Guarda la imagen filtrada
    % Img_filtradas(:,:,k) = I_filtrada;

    % Inicializar un vector para almacenar las posiciones de la superficie
    %Desde aca cambio el codigo
    superficie_y = zeros(1, Ly);
    %    superficie_x = zeros(1, Lx);

    % Recorrer cada columna para encontrar la superficie
    for col_y = 1:Ly
        fila = find(I_filtrada(:,col_y), 1, 'first');
        if ~isempty(fila)
            superficie_y(col_y) = fila;
        end
    end

    y_intervalo = superficie_y(limite_inferior:limite_superior);
    coeficientes = polyfit(a_intervalo, y_intervalo, 1);
    Pendientes(k,1) = rad2deg(atan(coeficientes(1)));
    y_ajustada = polyval(coeficientes, a_intervalo);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % OPCION GRAFICA EN VIVO
    if grafica == 1
        imagesc(flip(imread(files(k).name),2)),colormap(gray);
        set(gca,'Layer','top','XTick',...
            [0 134 234 334 434 534 634 734 834 934 1034 1134 1234 1334 1472],...
            'XTickLabel',...
            {'-14.68','-12','-10','-8','-6','-4','-2','0','2','4','6','8','10','12','14.76','','',''},...
            'YTick',[0 173 423 673 923 1173 1423],'YTickLabel',...
            {'28.46','25','20','15','10','5','0','-577','-777','-977','-1177','-1377','',''});
        hold on;
        plot(1:Ly, superficie_y, 'r', 'LineWidth', 2);
        plot(x_centro, y_centro,'k+','LineWidth', 2)
        %plot(x_centro, superficie(1049),'ko','MarkerFaceColor','auto')
        plot(a_intervalo, y_ajustada, 'w--', 'LineWidth', 2)
        hold off
        pause(1)
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Almacenar las posiciones de la superficie
    Superficies(:, k) = superficie_y';
    %    Superficies2(:, k) = superficie_x';
    % Opcional: Mostrar el progreso
    fprintf('Imagen procesa %d de %d\n', k, num_imagenes);
end

figure,set(gcf,'Position',[200 100 900 400])
subplot(4,4,[1 2 5 6 9 10 13 14]),imagesc(Largo_x,(0:k),Superficies'),axis xy
xlabel('$x$','Interpreter','latex')
ylabel('$t$','Interpreter','latex')
subplot(4,4,[3 4]),plot(Area_particulas(:,1))
xlabel('$t$','Interpreter','latex')
ylabel('$A$ particulas','Interpreter','latex')
subplot(4,4,[7 8]),plot(Area_particulas(:,2))
xlabel('$t$','Interpreter','latex')
ylabel('$A$ (cm2)','Interpreter','latex')
subplot(4,4,[11 12]),plot(Area_particulas(:,3))
xlabel('$t$','Interpreter','latex')
ylabel('$A$ vacio','Interpreter','latex')
% HAY QUE AMONONARLA PARA QUE SE VEA LA COMPARACION DEL ANGULO Y EL CENTRO
% DE MASA
subplot(4,4,[15 16]),plotyy([1:200],Pendientes,[1:200],centros_de_masa)
xlabel('$t$','Interpreter','latex')
ylabel('$a$ angulo','Interpreter','latex')