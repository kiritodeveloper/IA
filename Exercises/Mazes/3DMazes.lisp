;Jesús Alexis Torreblanca Faces

;Cargamos la libreria para comenzar a trabajar con ella
(load "maze_lib.lisp")

;Algoritmo al menu de la pagina principal
(add-algorithm 'depth-first)
(add-algorithm 'breath-first)
(add-algorithm 'best-first)
(add-algorithm 'A*)

;Permite saber para cada problema la frontera de busqueda y memoria
(defparameter *open*  '())
(defparameter *memory* '())

;Permite almacenar los datos del laberinto
(defparameter *id* 0)
(defparameter *current-ancestor* nil)
(defparameter *solution* nil)
(defparameter *filas*  nil)
(defparameter *columnas* nil)
(defparameter *sol* nil)

;Permite saber de donde vino el puente
(defparameter *puente* 0)
;Definicion de operadores
(defparameter *operadores* '((:Mover-Arriba 0)
                       (:Mover-Arriba-Derecha 1)
                       (:Mover-Derecha 2)
                       (:Mover-Abajo-Derecha 3)
                       (:Mover-Abajo 4)
                       (:Mover-Abajo-Izquierda 5)
                       (:Mover-Izquierda 6)
                       (:Mover-Arriba-Izquierda 7)))

;[Funcion] Permite resetear todo
(defun reset-all ()
  (setq *open*   nil)
  (setq *memory*  nil)
  (setq *id*  0)
  (setq *sol* nil)
  (setq *puente* 0)
  (setq *current-ancestor*  nil)
  (setq *solution*  nil))

;[Funcion] Permite crear los nodos necesarios
(defun create-node (estado operador importancia)
  (incf *id*)
  (list (1- *id*) importancia estado *current-ancestor* (second operador)))

;[Funcion] Permite saber la distancia get-distance, esta basada en la idea de la ecuacion de la distancia entre
; dos puntos, pero con una ligera modificacion, solo obtenemos el maximo de: (x2-x1),(y2-y1)
(defun get-distance (estado)
  (+ (- (max (aref estado 0) (aref *goal* 0))
          (min (aref estado 0) (aref *goal* 0)))
       (- (max (aref estado 1) (aref *goal* 1))
          (min (aref estado 1) (aref *goal* 1)))))

(defun insert-to-open (estado operador metodoBusqueda)
  (let* ((nodo '()))
    (cond ((eql metodoBusqueda :depth-first )
           (setq nodo (create-node  estado operador nil))
           (push nodo *open* ))
          ((eql metodoBusqueda :breath-first )
           (setq nodo (create-node  estado operador nil))
           (setq *open*  (append *open*  (list nodo))))
		  ((eql metodoBusqueda :best-first)
           (setq nodo (create-node  estado operador (get-distance estado)))
           (push nodo *open* )
           (order-open)
		  ((eql metodoBusqueda :Astar)
           (setq nodo (create-node  estado operador (get-distance estado)))
           (setf (second nodo) (+ (second nodo) (get-cost nodo 0)))
           (if (remember-state-memory? (third nodo) *open* )
               (compare-node nodo *open* )
               (push nodo *open* ))
           (order-open)
		   )))

;[Funcion] Permite hacer get-cost, se usa para el algoritmo A*
(defun get-cost (nodo num)
  (labels ((locate-node (id lista)
             (cond ((null lista) nil)
                   ((eql id (first (first lista))) (first lista))
                   (T (locate-node id (rest lista))))))
    (let ((current (locate-node (fourth nodo) *memory*)))
      (loop while (not (null current)) do
        (setq num (incf num))
        (setq current (locate-node (fourth current) *memory*))))
   num))


;[Funcion] Permite obtener el ultimo elemento de la frontera de busqueda
(defun get-from-open ()
  (pop *open* ))

(defun order-open ()
  "Funcion que permite reordenar la frontera de busqueda"
  (setq *open* (stable-sort *open* #'< :key #'(lambda (x) (fifth x)))))

;[Funcion] Permite validar nuestro operador
(defun valid-operator? (op estado)
  (let* ((fila (aref estado 0))
         (columna (aref estado 1))
         (casillaActual (get-cell-walls fila columna))
         (operador (second op))
         (casillaArriba nil)
         (casillaAbajo nil)
         (casilla-Arriba-Derecha -1)
         (casilla-Abajo-Derecha -1)
         (casilla-Arriba-Izquierda -1)
         (casilla-Abajo-Izquierda -1)
         (casillaIzquierda nil)
         (casillaDerecha nil)
         (operadorPasado -1)
         (diagonal? nil))

    (if (not (= fila 0))
        (setq casillaArriba (get-cell-walls (1- fila) columna)))
    (if (not (= columna 0))
        (setq casillaIzquierda (get-cell-walls fila (1- columna))))
	  (if (not (= columna (1- *columnas*)))
        (setq casillaDerecha (get-cell-walls fila (1+ columna))))
    (if (not (= fila (1- *filas* )))
        (setq casillaAbajo (get-cell-walls (1+ fila) columna)))
    (if (not (or (null casillaArriba)(null casillaDerecha)))
        (setq casilla-Arriba-Derecha (get-cell-walls (1- fila) (1+ columna))))
    (if (not (or (null casillaDerecha) (null casillaAbajo)))
        (setq casilla-Abajo-Derecha (get-cell-walls (1+ fila) (1+ columna))))
    (if (not (or (null casillaIzquierda) (null casillaAbajo)))
        (setq casilla-Abajo-Izquierda (get-cell-walls (1+ fila) (1- columna))))
    (if (not (or (null casillaIzquierda) (null casillaArriba)))
        (setq casilla-Arriba-Izquierda (get-cell-walls (1- fila) (1- columna))))
    (if (not (or (null casillaArriba) (null casillaAbajo ) (null casillaIzquierda ) (null casillaDerecha )))
        (progn
          (if (and (not (or (= casillaArriba 16 ) (= casillaAbajo 16 ) (= casillaIzquierda 16 ) (= casillaDerecha 16 ) (= casillaActual 16 )))
                   (not (or (= casillaArriba 17 ) (= casillaAbajo 17 ) (= casillaIzquierda 17 ) (= casillaDerecha 17 ) (= casillaActual 17 ))))
              (setq diagonal? T))))
    (if (not ( null (fifth (first *memory*))))
        (setq operadorPasado (fifth(first *memory*))))
    (if (or (= casillaActual 16)(= casillaActual 17))
        (setq *puente* 1)(setq *puente* 0))


    (cond ((= operador 0)
    (cond ((null casillaArriba) nil)
          ((or (= casillaActual 16)(= casillaActual 17))
           (if (= operadorPasado 0) T nil))
          ((= (boole boole-and casillaActual 1) 0) T)
          (T nil)))
          ((= operador 1)
          (cond ((or (= casilla-Arriba-Derecha 16)(= casilla-Arriba-Derecha 17)) nil)
                ((null diagonal?) nil)
                ((or (null casillaArriba) (null casillaDerecha)) nil)
                ((and (or (= (boole boole-and casillaActual 1) 0)
                          (= (boole boole-and casillaDerecha 1) 0))
                      (or (= (boole boole-and casillaArriba 2) 0)
                          (= (boole boole-and casillaDerecha 1) 0))
                      (or (= (boole boole-and casillaArriba 2) 0)
                          (= (boole boole-and casillaActual 2) 0))
                      (or (= (boole boole-and casillaActual 1) 0)
                          (= (boole boole-and casillaActual 2) 0))) T)
                (T nil)))
          ((= operador 2)
          (cond ((null casillaDerecha) nil)
                ((or (= casillaActual 16)(= casillaActual 17))
                 (if (= operadorPasado 2) T nil))
                ((= (boole boole-and casillaActual 2) 0) T)
                (T nil)))
          ((= operador 3)
          (cond ((or (= casilla-Abajo-Derecha 16)(= casilla-Abajo-Derecha 17)) nil)
                ((null diagonal?) nil)
                ((or (null casillaDerecha) (null casillaAbajo)) nil)
                ((and (or (= (boole boole-and casillaActual 4) 0)
                          (= (boole boole-and casillaDerecha 4) 0))
                      (or (= (boole boole-and casillaAbajo 2) 0)
                          (= (boole boole-and casillaDerecha 4) 0))
                      (or (= (boole boole-and casillaAbajo 2) 0)
                          (= (boole boole-and casillaActual 2) 0))
                      (or (= (boole boole-and casillaActual 4) 0)
                          (= (boole boole-and casillaActual 2) 0))) T)
                (T nil)))
          ((= operador 4)
          (cond ((or (= casillaActual 16)(= casillaActual 17))
                 (if (= operadorPasado 4) T nil))
                ((null casillaAbajo) nil)
                ((= (boole boole-and casillaActual 4) 0) T)
                (T nil)))
          ((= operador 5)
          (cond ((or (= casilla-Abajo-Izquierda 16)(= casilla-Abajo-Izquierda 17)) nil)
                ((null diagonal?) nil)
                ((or (null casillaAbajo) (null casillaIzquierda)) nil)
                ((and (or (= (boole boole-and casillaActual 4) 0)
                         (= (boole boole-and casillaIzquierda 4) 0))
                     (or (= (boole boole-and casillaAbajo 8) 0)
                         (= (boole boole-and casillaIzquierda 4) 0))
                     (or (= (boole boole-and casillaAbajo 8) 0)
                         (= (boole boole-and casillaActual 8) 0))
                     (or (= (boole boole-and casillaActual 4) 0)
                         (= (boole boole-and casillaActual 8) 0))) T)
                (T nil)))
          ((= operador 6)
          (cond ((null casillaIzquierda) nil)
                ((or (= casillaActual 16)(= casillaActual 17))
                 (if (= operadorPasado 6) T nil))
                ((= (boole boole-and casillaActual 8) 0) T)
                (T nil)))
          ((= operador 7)
          (cond ((or (= casilla-Arriba-Izquierda 16)(= casilla-Arriba-Izquierda 17)) nil)
                ((null diagonal?) nil)
                ((or (null casillaArriba) (null casillaIzquierda)) nil)
                ((and (or (= (boole boole-and casillaActual 1) 0)
                         (= (boole boole-and casillaIzquierda 1) 0))
                     (or (= (boole boole-and casillaArriba 8) 0)
                         (= (boole boole-and casillaIzquierda 1) 0))
                     (or (= (boole boole-and casillaArriba 8) 0)
                         (= (boole boole-and casillaActual 8) 0))
                     (or (= (boole boole-and casillaActual 1) 0)
                         (= (boole boole-and casillaActual 8) 0))) T)
                (T nil)))
          (T nil))))

;[Funcion] Permite aplicar el operador al estado
(defun apply-operator (operador estado)
  (let* ((fila (aref estado 0))
         (columna (aref estado 1))
         (operador (first operador))
         (estadoFinal nil))

    (case operador
      (:Mover-Arriba (setq estadoFinal (make-array 3 :initial-contents (list (1- fila) columna *puente*))))
      (:Mover-Arriba-Derecha (setq estadoFinal (make-array 3 :initial-contents (list (1- fila) (1+ columna) *puente*))))
      (:Mover-Derecha (setq estadoFinal (make-array 3 :initial-contents (list fila (1+ columna) *puente*))))
      (:Mover-Abajo-Derecha (setq estadoFinal (make-array 3 :initial-contents (list (1+ fila) (1+ columna) *puente* ))))
      (:Mover-Abajo (setq estadoFinal (make-array 3 :initial-contents (list (1+ fila) columna *puente*))))
      (:Mover-Abajo-Izquierda (setq estadoFinal (make-array 3 :initial-contents (list (1+ fila) (1- columna) *puente*))))
      (:Mover-Izquierda (setq estadoFinal (make-array 3 :initial-contents (list fila (1- columna) *puente*))))
      (:Mover-Arriba-Izquierda (setq estadoFinal (make-array 3 :initial-contents (list (1- fila) (1- columna) *puente*))))
      (T "error"))
    estadoFinal))


;[Funcion] Permite ayudarnos en nuestro algoritmo A*
(defun compare-node (nodo listaMemoria)
  (let ((nodoAux nil))
    (cond ((null listaMemoria) (push nodo *open* ))
          ((and (equal (aref (third nodo) 0) (aref (third (first listaMemoria)) 0))
                (equal (aref (third nodo) 1) (aref (third (first listaMemoria)) 1)))
           (setq nodoAux (first listaMemoria))
           (if (< (second nodo) (second nodoAux))
               (progn (delete nodoAux listaMemoria)
                      (push nodo *open* ))))
          (T (compare-node nodo (rest listaMemoria))))))

;[Funcion] Permite expand el estado
(defun expand (estado)
  (let ((descendientes nil) (nuevoEstado nil))
    (dolist (operador *operadores* descendientes)
      (if (valid-operator? operador estado)
          (progn
            (setq nuevoEstado (apply-operator operador estado))
            (setq descendientes (cons (list nuevoEstado operador) descendientes)))))))

;[Funcion] Permite filtrar nuestra memoria
(defun filter-memories (listaDeEstados lista)
  (cond ((null listaDeEstados) nil)
        ((remember-state-memory? (first (first listaDeEstados)) lista)
         (filter-memories (rest listaDeEstados) lista))
        (T (cons (first listaDeEstados) (filter-memories (rest listaDeEstados) lista)))))

;[Funcion] Es un predicado, devuelve verdadero o falso si recuerda el estado en la memoria
(defun remember-state-memory? (estado memoria)
  (cond ((null memoria) nil)
        ((and (equal (aref estado 0) (aref (third (first memoria)) 0))
              (equal (aref estado 1) (aref (third (first memoria)) 1))
              (and (= 0 (aref (third (first memoria)) 2))
                   (= 0 (aref estado 2)))) T)
        (T (remember-state-memory? estado (rest memoria)))))

;[Funcion] Permite extraer la solucion
(defun extract-solution (nodo)
  (labels ((locate-node (id lista)
             (cond ((null lista) nil)
                   ((eql id (first (first lista))) (first lista))
                   (T (locate-node id (rest lista))))))
    (let ((current (locate-node (first nodo) *memory*)))
      (loop while (not (null current)) do
        (if (not (null (fifth current)))
        (push (fifth current) *sol*))
        (setq current (locate-node (fourth current) *memory*))))
    *sol*))


(defun depth-first ()
  (reset-all)
  (let ((nodo nil)
        (estado nil)
        (sucesores '())
        (inicialColumna nil)
        (inicialFila nil)
        (meta-encontrada nil)
        (metodo :depth-first))
	(setq *filas*  (get-maze-rows))
	(setq *columnas* (get-maze-cols))
  (setq inicialColumna (aref *start* 0))
  (setq inicialFila (aref *start* 1))
  (insert-to-open (make-array 3 :initial-contents (list inicialColumna inicialFila 0 )) nil metodo)
  (loop until (or meta-encontrada (null *open* )) do
       (setq nodo (get-from-open)
             estado (third nodo))
       (push nodo *memory*)
       (cond ((and (equal (aref *goal* 0) (aref estado 0))
                   (equal (aref *goal* 1) (aref estado 1)))
              (setq *solution* (extract-solution nodo))
              (setq meta-encontrada T))
             (T (setq *current-ancestor* (first nodo)
                      sucesores (filter-memories (expand estado) *memory*))
                (loop for elem in sucesores do
                     (insert-to-open (first elem) (second elem) metodo)))))))

(defun breath-first ()
  (reset-all)
      (let ((nodo nil)
            (estado nil)
            (sucesores '())
            (meta-encontrada nil)
            (inicialColumna nil)
            (inicialFila nil)
            (metodo :breath-first))
		(setq *filas*  (get-maze-rows))
		(setq *columnas* (get-maze-cols))
    (setq inicialColumna (aref *start* 0))
    (setq inicialFila (aref *start* 1))
    (insert-to-open (make-array 3 :initial-contents (list inicialColumna inicialFila 0 )) nil metodo)
    (loop until (or meta-encontrada
                    (null *open* )) do
         (setq nodo (get-from-open) estado (third nodo))
         (push nodo *memory*)
         (cond ((and (equal (aref *goal* 0) (aref estado 0))
                     (equal (aref *goal* 1) (aref estado 1)))
                (setq *solution* (extract-solution nodo))
                (setq meta-encontrada T))
               (T (setq *current-ancestor* (first nodo)
                        sucesores (filter-memories (expand estado) *memory*))
                  (loop for elem in sucesores do
                       (insert-to-open (first elem) (second elem) metodo)))))))

(defun best-first ()
  (reset-all)
      (let ((nodo nil)
            (estado nil)
            (sucesores '())
            (inicialColumna nil)
            (inicialFila nil)
            (meta-encontrada nil)
            (metodo :best-first))
        (setq *filas*  (get-maze-rows))
        (setq *columnas* (get-maze-cols))
        (setq inicialColumna (aref *start* 0))
        (setq inicialFila (aref *start* 1))
        (insert-to-open (make-array 3 :initial-contents (list inicialColumna inicialFila 0 )) nil metodo)
        (loop until (or meta-encontrada (null *open* )) do
             (setq nodo (get-from-open)
                   estado (third nodo))
             (push nodo *memory*)
             (cond ((and (equal (aref *goal* 0) (aref estado 0))
                         (equal (aref *goal* 1) (aref estado 1)))
                    (setq *solution* (extract-solution nodo))
                    (setq meta-encontrada T))
                   (T (setq *current-ancestor* (first nodo)
                            sucesores (filter-memories (filter-memories (expand estado) *open* ) *memory*))
                      (loop for elem in sucesores do
                           (insert-to-open (first elem) (second elem) metodo)))))))

(defun A* ()
(reset-all)
      (let ((nodo nil)
            (estado nil)
            (sucesores '())
            (inicialColumna nil)
            (inicialFila nil)
            (meta-encontrada nil)
            (metodo :Astar))
        (setq *filas*  (get-maze-rows))
        (setq *columnas* (get-maze-cols))
        (setq inicialColumna (aref *start* 0))
        (setq inicialFila (aref *start* 1))
        (insert-to-open (make-array 3 :initial-contents (list inicialColumna inicialFila 0 )) nil metodo)
        (loop until (or meta-encontrada (null *open* )) do
             (setq nodo (get-from-open)
                   estado (third nodo))
             (push nodo *memory*)
             (cond ((and (equal (aref *goal* 0) (aref estado 0))
                         (equal (aref *goal* 1) (aref estado 1)))
                    (setq *solution* (extract-solution nodo))
                    (setq meta-encontrada T))
                   (T (setq *current-ancestor* (first nodo)
                            sucesores (filter-memories (expand estado) *memory*))
                      (loop for elem in sucesores do
                           (insert-to-open (first elem) (second elem) metodo)))))))

;[Inicio] Iniciamos nuestro laberinto
(start-maze)
