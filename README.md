---
editor_options: 
  markdown: 
    wrap: 72
---

# echo_pattern_TE

Repositorio en R para comparar poses humanas extraídas con OpenPose.
Incluye funciones para medir similitud estructural entre esqueletos y
distancia espacial entre keypoints, útil en análisis de gestos,
sincronía conductual e interacción multimodal. Solo requiere el paquete
vegan.

# Echo Pattern

Funciones en R para comparar la similitud entre dos esqueletos extraídos
de vídeo, usando coordenadas normalizadas de puntos corporales, faciales
o manuales.

El código permite comparar esqueletos mediante dos enfoques:

Correlación de Mantel: compara la estructura interna de distancias entre
puntos. Distancia euclídea media: calcula la diferencia directa punto a
punto entre dos esqueletos. Dependencias install.packages('vegan')
install.packages('data.table') library(vegan) library(data.table)
Estructura esperada de los datos

Las funciones esperan un objeto tipo data.table llamado, por ejemplo,
video_dt, con al menos estas columnas:

Columna Descripción frame Número o identificador del frame people_id
Identificador de la persona detectada type_points Tipo de puntos
detectados nx Coordenada X normalizada ny Coordenada Y normalizada

Los valores válidos para type_points son:

'pose_keypoints' 'face_keypoints' 'hand_left_keypoints'
'hand_right_keypoints'

Además, las funciones aceptan:

'all_points'

para usar todos los puntos disponibles del esqueleto.

Función echo_pattern()

Compara dos esqueletos mediante una prueba de Mantel.

echo_pattern(frame_1, frame_2, people_id_1, people_id_2, video_dt,
typepoints) Argumentos Argumento Descripción frame_1 Frame del primer
esqueleto frame_2 Frame del segundo esqueleto people_id_1 ID de la
persona en el primer frame people_id_2 ID de la persona en el segundo
frame video_dt data.table con los datos del vídeo typepoints Tipo de
puntos a comparar Salida

Devuelve un vector con:

Valor Descripción r Estadístico de correlación de Mantel p Valor p
asociado

Ejemplo:

echo_pattern( frame_1 = 10, frame_2 = 20, people_id_1 = 1, people_id_2 =
1, video_dt = video_dt, typepoints = 'pose_keypoints' )

Salida esperada:

```         
    r         p 
```

0.8423152 0.0010000 Interpretación de echo_pattern() r cercano a 1: los
dos esqueletos tienen una estructura de distancias muy parecida. r
cercano a 0: no hay una relación clara entre las estructuras. r cercano
a -1: las estructuras son opuestas. p indica si la similitud observada
es estadísticamente significativa.

Esta función es útil cuando interesa saber si la configuración global
del cuerpo se mantiene entre dos frames o dos personas.

Función echo_pattern_eucdis()

Calcula la distancia euclídea media punto a punto entre dos esqueletos.

echo_pattern_eucdis(frame_1, frame_2, people_id_1, people_id_2,
video_dt, typepoints) Argumentos

Son los mismos que en echo_pattern().

Salida

Devuelve un vector con:

Valor Descripción distancia Distancia euclídea media entre puntos
equivalentes

Ejemplo:

echo_pattern_eucdis( frame_1 = 10, frame_2 = 20, people_id_1 = 1,
people_id_2 = 1, video_dt = video_dt, typepoints = 'all_points' )

Salida esperada:

distancia 0.0348291 Interpretación de echo_pattern_eucdis() Valores
cercanos a 0 indican que los esqueletos son muy similares punto a punto.
Valores más altos indican mayor diferencia espacial entre ambos
esqueletos.

Esta función es útil cuando interesa medir una diferencia directa de
posición entre dos esqueletos.

Gestión de valores perdidos

Ambas funciones eliminan automáticamente los puntos con valores no
finitos en cualquiera de los dos esqueletos:

NA NaN Inf -Inf

Si después de eliminar esos puntos quedan menos de 3 puntos válidos, la
función devuelve NA.

Errores y advertencias

Si typepoints no es válido, la función detiene la ejecución con un
error:

typepoints debe ser pose_keypoints, face_keypoints, hand_left_keypoints,
hand_right_keypoints o all_points

En echo_pattern_eucdis(), si los dos esqueletos no tienen el mismo
número de puntos, se devuelve NA y aparece una advertencia:

Los esqueletos no tienen el mismo número de puntos Diferencias entre
ambas funciones Función Qué mide Resultado echo_pattern() Similitud de
la estructura interna de distancias r y p echo_pattern_eucdis()
Diferencia directa punto a punto Distancia media Uso recomendado

Usa echo_pattern() si quieres comparar la forma general o patrón del
esqueleto.

Usa echo_pattern_eucdis() si quieres medir cuánto se han desplazado los
puntos entre dos esqueletos.

Ejemplo completo library(data.table) library(vegan)

resultado_mantel \<- echo_pattern( frame_1 = 1, frame_2 = 2, people_id_1
= 0, people_id_2 = 0, video_dt = video_dt, typepoints = 'pose_keypoints'
)

resultado_distancia \<- echo_pattern_eucdis( frame_1 = 1, frame_2 = 2,
people_id_1 = 0, people_id_2 = 0, video_dt = video_dt, typepoints =
'pose_keypoints' )

resultado_mantel resultado_distancia Notas El orden de los puntos debe
ser equivalente entre los dos esqueletos. Las coordenadas nx y ny
deberían estar normalizadas para que las comparaciones sean
consistentes. La prueba de Mantel usa 999 permutaciones. Para
comparaciones masivas entre muchos frames, se recomienda aplicar estas
funciones dentro de bucles o con funciones tipo lapply.
