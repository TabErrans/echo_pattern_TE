library(data.table)

echo_pattern_euclidean <- function(frame_1,
                                   frame_2,
                                   people_id_1,
                                   people_id_2,
                                   video_dt,
                                   group = NULL,
                                   points_to_compare = NULL,
                                   frames_path = NULL,
                                   frame_file_pattern = "frame_%s.png",
                                   open_frames = FALSE,
                                   min_points = 1) {
  
  # ------------------------------------------------------------
  # 1. Comprobación de columnas necesarias
  # ------------------------------------------------------------
  
  required_cols <- c(
    "frame",
    "people_id",
    "type_points",
    "point_id",
    "nx",
    "ny"
  )
  
  missing_cols <- setdiff(required_cols, names(video_dt))
  
  if (length(missing_cols) > 0) {
    stop(
      paste(
        "Faltan las siguientes columnas en video_dt:",
        paste(missing_cols, collapse = ", ")
      )
    )
  }
  
  video_dt <- as.data.table(video_dt)
  
  
  # ------------------------------------------------------------
  # 2. Comprobación del modo de selección
  # ------------------------------------------------------------
  
  valid_groups <- c(
    "pose_keypoints",
    "face_keypoints",
    "hand_left_keypoints",
    "hand_right_keypoints",
    "all_points"
  )
  
  # Si no se indica nada, por defecto se comparan todos los puntos
  if (is.null(group) && is.null(points_to_compare)) {
    group <- "all_points"
  }
  
  # No se permite usar grupo y puntos concretos a la vez
  if (!is.null(group) && !is.null(points_to_compare)) {
    stop("Debes elegir una sola forma de selección: 'group' o 'points_to_compare', pero no ambas a la vez.")
  }
  
  if (!is.null(group) && !(group %in% valid_groups)) {
    stop(
      paste(
        "group debe ser uno de los siguientes valores:",
        paste(valid_groups, collapse = ", ")
      )
    )
  }
  
  
  # ------------------------------------------------------------
  # 3. Función interna para extraer un esqueleto
  # ------------------------------------------------------------
  
  get_skeleton <- function(selected_frame, selected_people_id) {
    
    skeleton <- video_dt[
      frame == selected_frame & people_id == selected_people_id,
      .(type_points, point_id, nx, ny)
    ]
    
    # Selección por grupo
    if (!is.null(group)) {
      if (group != "all_points") {
        skeleton <- skeleton[type_points == group]
      }
    }
    
    # Selección por puntos concretos
    if (!is.null(points_to_compare)) {
      
      # Caso 1: points_to_compare es un vector de point_id
      if (is.vector(points_to_compare) && !is.data.frame(points_to_compare)) {
        skeleton <- skeleton[point_id %in% points_to_compare]
      }
      
      # Caso 2: points_to_compare es una tabla con type_points y point_id
      if (is.data.frame(points_to_compare)) {
        
        points_dt <- as.data.table(points_to_compare)
        
        if (!all(c("type_points", "point_id") %in% names(points_dt))) {
          stop("Si points_to_compare es una tabla, debe contener las columnas 'type_points' y 'point_id'.")
        }
        
        skeleton <- merge(
          skeleton,
          points_dt,
          by = c("type_points", "point_id"),
          all = FALSE
        )
      }
    }
    
    return(skeleton)
  }
  
  
  # ------------------------------------------------------------
  # 4. Extraer los dos esqueletos
  # ------------------------------------------------------------
  
  skeleton_1 <- get_skeleton(frame_1, people_id_1)
  skeleton_2 <- get_skeleton(frame_2, people_id_2)
  
  
  # ------------------------------------------------------------
  # 5. Comprobar duplicados
  # ------------------------------------------------------------
  
  duplicated_1 <- skeleton_1[
    duplicated(skeleton_1[, .(type_points, point_id)])
  ]
  
  duplicated_2 <- skeleton_2[
    duplicated(skeleton_2[, .(type_points, point_id)])
  ]
  
  if (nrow(duplicated_1) > 0 || nrow(duplicated_2) > 0) {
    stop("Hay puntos duplicados para el mismo type_points y point_id. Revisa video_dt antes de comparar.")
  }
  
  
  # ------------------------------------------------------------
  # 6. Emparejar puntos equivalentes
  # ------------------------------------------------------------
  
  paired_points <- merge(
    skeleton_1,
    skeleton_2,
    by = c("type_points", "point_id"),
    suffixes = c("_1", "_2")
  )
  
  
  # ------------------------------------------------------------
  # 7. Eliminar puntos con coordenadas no válidas
  # ------------------------------------------------------------
  
  paired_points <- paired_points[
    is.finite(nx_1) & is.finite(ny_1) &
      is.finite(nx_2) & is.finite(ny_2)
  ]
  
  
  # ------------------------------------------------------------
  # 8. Comprobar número mínimo de puntos
  # ------------------------------------------------------------
  
  if (nrow(paired_points) < min_points) {
    warning("No hay suficientes puntos válidos para calcular la distancia.")
    
    return(list(
      distance = NA_real_,
      point_distances = NULL,
      n_points = nrow(paired_points),
      frame_1 = frame_1,
      frame_2 = frame_2,
      people_id_1 = people_id_1,
      people_id_2 = people_id_2,
      frames_path = frames_path
    ))
  }
  
  
  # ------------------------------------------------------------
  # 9. Calcular distancia euclídea punto a punto
  # ------------------------------------------------------------
  
  paired_points[, distance := sqrt(
    (nx_1 - nx_2)^2 +
      (ny_1 - ny_2)^2
  )]
  
  
  # ------------------------------------------------------------
  # 10. Calcular distancia media global
  # ------------------------------------------------------------
  
  mean_distance <- mean(paired_points$distance)
  
  
  # ------------------------------------------------------------
  # 11. Crear rutas opcionales a fotogramas
  # ------------------------------------------------------------
  
  frame_1_path <- NULL
  frame_2_path <- NULL
  
  if (!is.null(frames_path)) {
    
    frame_1_path <- file.path(
      frames_path,
      sprintf(frame_file_pattern, frame_1)
    )
    
    frame_2_path <- file.path(
      frames_path,
      sprintf(frame_file_pattern, frame_2)
    )
    
    if (open_frames) {
      
      if (file.exists(frame_1_path)) {
        utils::browseURL(normalizePath(frame_1_path))
      } else {
        warning(paste("No existe el archivo:", frame_1_path))
      }
      
      if (file.exists(frame_2_path)) {
        utils::browseURL(normalizePath(frame_2_path))
      } else {
        warning(paste("No existe el archivo:", frame_2_path))
      }
    }
  }
  
  
  # ------------------------------------------------------------
  # 12. Devolver resultados
  # ------------------------------------------------------------
  
  return(list(
    distance = mean_distance,
    point_distances = paired_points[
      ,
      .(
        type_points,
        point_id,
        nx_1,
        ny_1,
        nx_2,
        ny_2,
        distance
      )
    ],
    n_points = nrow(paired_points),
    frame_1 = frame_1,
    frame_2 = frame_2,
    people_id_1 = people_id_1,
    people_id_2 = people_id_2,
    selection = ifelse(!is.null(group), group, "specific_points"),
    frames_path = frames_path,
    frame_1_path = frame_1_path,
    frame_2_path = frame_2_path
  ))
}