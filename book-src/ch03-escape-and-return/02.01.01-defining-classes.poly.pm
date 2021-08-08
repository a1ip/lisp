#lang pollen

◊subsubsection*{Определение классов}

◊indexC{define-class}
Классы определяется с~помощью формы ◊ic{define-class} следующим образом:

◊code:lisp{
(define-class ◊ii{класс} ◊ii{суперкласс}
  (◊ii{поля}...) )
}

◊indexR{поля}
◊indexR{аксессоры}
◊noindent
Эта форма определяет ◊ii{класс}, который наследует поля и методы ◊ii{суперкласса}, а~также имеет свои собственные ◊ii{поля}.
Вместе с~классом определяется набор вспомогательных функций.
Функция-конструктор ◊ic{make-◊ii{класс}} создаёт объекты нового класса;
конструктор принимает столько аргументов, сколько у~класса полей, в~порядке их определения.
Каждому полю соответствует пара функций-аксессоров.
Названия аксессоров чтения состоят из имени класса и имени поля, разделённых дефисом.
Названия аксессоров записи аналогичны аксессорам чтения, добавляя ◊ic{set-} в~начале и восклицательный знак в~конце.
Возвращаемое значение аксессоров записи не~определено.
Предикат ◊ic{◊ii{класс}?} проверяет, является~ли объект экземпляром указанного класса.

◊indexC{Object}
Корнем иерархии наследования является класс ◊ic{Object}, не~имеющий полей.

Например, следующий класс

◊code:lisp{
(define-class continuation Object (k))
}

◊noindent
определит такие сопутствующие функции:

◊code:lisp{
(make-continuation k)         ; конструктор
(continuation-k c)            ; аксессор чтения
(set-continuation-k! c k)     ; аксессор записи
(continuation? o)             ; предикат принадлежности
}
