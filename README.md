# `echo_pattern_TE`

Repositorio en R para comparar poses humanas extraídas con OpenPose. Incluye funciones para medir similitud estructural entre esqueletos y distancia espacial entre `keypoints`, útil en análisis de gestos, sincronía conductual e interacción multimodal. Solo requiere el paquete `vegan`.

# Echo Pattern

# Fundamento Matemático

## Objetivo

Echo Pattern TE tiene como objetivo comparar dos esqueletos representados mediante puntos corporales para estimar si ambos pertenecen a la misma persona.

Cada esqueleto se modela como una matriz de coordenadas. Si se detectan (n) puntos corporales, cada esqueleto puede representarse como:

$$
A =
\begin{bmatrix}
x_1 & y_1 \
x_2 & y_2 \
\vdots & \vdots \
x_n & y_n
\end{bmatrix}
$$

donde cada fila representa un punto del cuerpo, por ejemplo hombros, codos, muñecas, caderas, rodillas o tobillos.

------------------------------------------------------------------------

## Comparación entre dos esqueletos

Dados dos esqueletos (A) y (B), el objetivo es medir cuánto se parecen sus estructuras corporales.

$$
A =
{a_1, a_2, ..., a_n}
$$

$$
B =
{b_1, b_2, ..., b_n}
$$

donde (a_i) y (b_i) representan el mismo punto anatómico en cada esqueleto.

La diferencia entre ambos esqueletos puede calcularse como la distancia media entre puntos equivalentes:

$$
D(A,B)=
\frac{1}{n}
\sum_{i=1}^{n}
|a_i-b_i|
$$

donde (\|a_i-b_i\|) es la distancia euclidiana entre el punto (i) del primer esqueleto y el punto (i) del segundo.

En 2D, esta distancia se calcula como:

$$
|a_i-b_i|=
\sqrt{
(x_i^A-x_i^B)^2+
(y_i^A-y_i^B)^2
}
$$

------------------------------------------------------------------------

## Normalización

Antes de comparar dos esqueletos, es necesario normalizarlos. Esto evita que diferencias de posición, escala o tamaño en la imagen afecten al resultado.

Por ejemplo, dos esqueletos pueden representar a la misma persona, pero aparecer en posiciones distintas dentro de la imagen. Para corregirlo, se puede trasladar cada esqueleto respecto a un punto de referencia, como el centro de la cadera o el centro del torso.

Sea (r) el punto de referencia del esqueleto. Cada punto se normaliza como:

$$
a_i' = a_i - r_A
$$

$$
b_i' = b_i - r_B
$$

De esta forma, ambos esqueletos quedan centrados en un mismo origen.

También puede aplicarse una normalización por escala, dividiendo las coordenadas entre una medida corporal estable, como la distancia entre hombros o la longitud del torso:

$$
a_i'' =
\frac{a_i'}{s_A}
$$

$$
b_i'' =
\frac{b_i'}{s_B}
$$

donde (s_A) y (s_B) representan el factor de escala de cada esqueleto.

-------------------------------------------------------------------------------------- ## Matriz de diferencias

Una vez normalizados los esqueletos, puede calcularse una matriz de diferencias:

$$
E = A'' - B''
$$

Esta matriz contiene la diferencia entre cada punto corporal de ambos esqueletos.

A partir de ella, se puede obtener un error global mediante la norma de Frobenius:

$$
\lVert E \rVert_F =
\sqrt{
\sum_{i=1}^{n}
\sum_{j=1}^{d}
E_{ij}^{2}
}
$$

donde:

-   $n$ es el número de puntos corporales.
-   $d$ es la dimensión de cada punto, normalmente 2 o 3.
-   $E_{ij}$ es la diferencia entre las coordenadas de ambos esqueletos.

Cuanto menor sea la norma de Frobenius, mayor será la similitud entre ambos esqueletos. \## Puntuación de similitud

Para transformar la distancia en una puntuación de similitud, puede utilizarse una función decreciente:

$$
S(A,B)=
\frac{1}{1+\lVert A''-B'' \rVert_F}
$$

Esta puntuación toma valores cercanos a 1 cuando los esqueletos son muy parecidos, y valores cercanos a 0 cuando son muy diferentes.

------------------------------------------------------------------------

## Criterio de decisión

Finalmente, se define un umbral (\tau) para decidir si dos esqueletos pertenecen probablemente a la misma persona:

$$
S(A,B) \geq \tau
$$

Si la similitud supera el umbral, el sistema considera que ambos esqueletos podrían pertenecer a la misma persona.

Si no lo supera, se considera que los esqueletos presentan diferencias suficientes como para corresponder a personas distintas.

------------------------------------------------------------------------

## Interpretación

El método se basa en comparar la geometría corporal relativa, no la posición absoluta de la persona en la imagen.

Por ello, el proceso general es:

1.  Detectar los puntos corporales de cada persona.
2.  Representar cada esqueleto como una matriz de coordenadas.
3.  Normalizar posición y escala.
4.  Comparar puntos equivalentes entre ambos esqueletos.
5.  Calcular una puntuación global de similitud.
6.  Decidir si ambos esqueletos pertenecen a la misma persona mediante un umbral.

Este enfoque permite comparar poses humanas de forma matemática, utilizando la estructura espacial de los puntos corporales como una firma geométrica aproximada de cada individuo.
