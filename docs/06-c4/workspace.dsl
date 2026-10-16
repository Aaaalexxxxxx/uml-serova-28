workspace "Служба такси" "Учебная модель" {

    model {
        client     = person "Клиент" "Заказывает поездку, оплачивает, оценивает водителя"
        driver     = person "Водитель" "Принимает заказы, выполняет поездки, оценивает клиента"
        dispatcher = person "Диспетчер" "Разрешает споры между клиентом и водителем"

        pay  = softwareSystem "Платёжный шлюз" "Проводит оплату и возвраты по поездкам" "Внешняя"
        maps = softwareSystem "Картографический сервис" "Геокодирование адресов, расчёт маршрута" "Внешняя"

        taxi = softwareSystem "Служба такси" "Заказ поездок, подбор водителей, ценообразование" {

            mobile = container "Мобильное приложение" "Заказ поездки, оплата, оценка водителя" "Kotlin / Swift" {
                orderScreen   = component "OrderScreen" "Экран заказа поездки" "Kotlin / Swift"
                payScreen     = component "PaymentScreen" "Экран оплаты" "Kotlin / Swift"
                ratingScreen  = component "RatingScreen" "Экран оценки водителя" "Kotlin / Swift"
            }

            web = container "Веб-панель диспетчера" "Просмотр активных заказов, разрешение споров" "React" {
                ordersView = component "OrdersView" "Список активных заказов" "React"
                disputeView = component "DisputeView" "Разрешение споров" "React"
            }

            api = container "Backend API" "Бизнес-логика заказов, тарифов, водителей, отзывов" "Kotlin / Spring Boot" {
                orderCtrl   = component "OrderController" "REST-эндпоинты заказов" "Spring MVC"
                rideCtrl    = component "RideController" "REST-эндпоинты поездок" "Spring MVC"
                ratingCtrl  = component "RatingController" "REST-эндпоинты отзывов" "Spring MVC"

                orderSvc    = component "OrderService" "Жизненный цикл заказа" "Kotlin"
                matchSvc    = component "MatchService" "Подбор водителя" "Kotlin"
                priceSvc    = component "PriceService" "Расчёт стоимости" "Kotlin"
                ratingSvc   = component "RatingService" "Обработка отзывов" "Kotlin"
                eventPub    = component "EventPublisher" "Публикация доменных событий" "Kotlin"

                orderRepo   = component "OrderRepository" "Доступ к заказам, поездкам" "Spring Data JPA"
                userRepo    = component "UserRepository" "Доступ к клиентам, водителям" "Spring Data JPA"
            }

            pricer  = container "Сервис ценообразования" "Расчёт стоимости с учётом тарифа и коэффициента спроса" "Kotlin"
            matcher = container "Сервис подбора водителей" "Поиск ближайшего свободного водителя" "Kotlin"
            worker  = container "Планировщик" "Таймауты, напоминания, начисление штрафов" "Kotlin"

            db  = container "Основная БД" "Заказы, поездки, пользователи, тарифы, отзывы, транзакции" "PostgreSQL" "Database"
            bus = container "Очередь событий" "Доменные события: заказ создан, водитель назначен, поездка завершена" "RabbitMQ" "Queue"

            # Связи уровня Container
            client     -> mobile "Пользуется" "HTTPS"
            driver     -> mobile "Пользуется" "HTTPS"
            dispatcher -> web    "Пользуется" "HTTPS"

            mobile -> api "Вызывает" "JSON/HTTPS"
            web    -> api "Вызывает" "JSON/HTTPS"

            api -> pricer  "Запрашивает стоимость" "JSON/HTTPS"
            api -> matcher "Передаёт заказ на подбор" "JSON/HTTPS"
            api -> db      "Читает и пишет" "JDBC"
            api -> bus     "Публикует события" "AMQP"
            api -> pay     "Проводит оплату" "HTTPS"
            api -> maps    "Запрашивает маршрут" "HTTPS"

            matcher -> db  "Читает статусы водителей" "JDBC"
            matcher -> bus "Публикует DriverAssigned" "AMQP"
            pricer  -> db  "Читает тарифы" "JDBC"
            bus     -> worker "Доставляет события" "AMQP"
            worker  -> db  "Обновляет статусы" "JDBC"
            worker  -> mobile "Отправляет Push-уведомления" "HTTPS"

            # Связи уровня Component (внутри Backend API)
            mobile -> orderCtrl "POST /orders" "JSON/HTTPS"
            mobile -> rideCtrl  "GET /rides/{id}" "JSON/HTTPS"
            web    -> orderCtrl "GET /orders" "JSON/HTTPS"
            web    -> ratingCtrl "GET /ratings" "JSON/HTTPS"

            orderCtrl  -> orderSvc "вызывает"
            rideCtrl   -> orderSvc "вызывает"
            ratingCtrl -> ratingSvc "вызывает"

            orderSvc  -> matchSvc "передаёт заказ на подбор"
            orderSvc  -> priceSvc "запрашивает стоимость"
            orderSvc  -> orderRepo "использует"
            orderSvc  -> eventPub "публикует OrderCreated"
            matchSvc  -> matcher "вызывает" "JSON/HTTPS"
            priceSvc  -> pricer "вызывает" "JSON/HTTPS"
            ratingSvc -> userRepo "использует"

            orderRepo -> db  "читает и пишет" "JDBC"
            userRepo  -> db  "читает и пишет" "JDBC"
            eventPub  -> bus "публикует события" "AMQP"
            orderSvc  -> pay "проводит оплату" "HTTPS"
            matchSvc  -> maps "запрашивает маршрут" "HTTPS"
        }
    }

    views {
        systemContext taxi "Context" {
            include *
            autolayout lr
        }

        container taxi "Containers" {
            include *
            autolayout lr
        }

        component api "Components" {
            include *
            autolayout lr
        }

        theme default
    }
}