
# Роли

---

- UI - Арсен
- Dev/DB - Тимур
- Консьюмер - Рия
  - Продюсер - Аделя
- Логика - Ролан

# Описание

---

**Chat Application with Kafka**

Build a distributed chat system using Kafka for message handling. Clients can join rooms, send messages, and receive real-time updates.

**Features:**

- **A:** A single Kafka topic where all users chat and see each other’s messages
- **B:** Separate Kafka topics per chat room with users subscribing to the one they join
- **C:** A single topic with message filters (tagged messages only shown to specific users)

**Validation Checklist:**

- Produce and consume message logs showing the sequence and delivery
- Simulate join/leave of users and confirm message isolation or filtering
- Visualize message flow per topic or per user