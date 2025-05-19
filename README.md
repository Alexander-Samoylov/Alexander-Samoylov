<div id="header" align="center">
  <img src="https://i.giphy.com/media/v1.Y2lkPTc5MGI3NjExMjBmdG5ycnRrYjh4bTA3eXVtdGltbGFicjd4NGFtcm8yMHZ2ZGJybCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/UPqYp2tj61XlBhlPbH/giphy.gif" width="500"/>
</div>
<div id="badges" align="center">
   <a href="https://www.instagram.com/samoylov_alxdr/profilecard/?igsh=MWdiend3Y3Fmb3Vhbg==">
  <img src="https://img.shields.io/badge/Instagram-orange?logo=instagram&logoColor=white&style=for-the-badge" alt="Instagram Badge"/>
  <a>
  <a href="https://vk.com/san4ez90">
  <img src="https://img.shields.io/badge/Vk-blue?style=for-the-badge&logo=vk&logoColor=white" alt="Vk Badge"/>
  <a>
  <div>
  <img src="https://komarev.com/ghpvc/?username=Alexander-Samoylov&style=flat-square&color=blue" alt=""/>
    <h1>
  hey there
  <img src="https://media.giphy.com/media/hvRJCLFzcasrR4ia7z/giphy.gif" width="30px"/>
</h1>
</div>
graph TD
A[Идея/Проблема] -->|PO/Analyst| B(Backlog)
B -->|Приоритизация| C["Тикет в Jira<br>(User Story/Bug/Task)"]
C -->|PM/PO| D{Тип задачи?}
D -->|Баг| E[Тестировщик: воспроизведение]
D -->|Фича| F[Аналитик: уточнение требований]
D -->|Тех. долг| G[Tech Lead: оценка]
E --> H[Разработчик: исправление]
F --> I[Дизайнер: макеты]
I --> J[Разработчик: реализация]
G --> K[Включение в спринт]
H & J & K --> L[Ревью кода (Team Lead)]
L --> M[Тестирование]
M --> N{Готово?}
N -->|Да| O[Деплой]
N -->|Нет| P[Возврат на доработку]
O --> Q[Подтверждение PO]
Q --> R[Закрытие задачи]
