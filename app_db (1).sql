-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: db
-- Generation Time: Apr 21, 2026 at 06:31 AM
-- Server version: 8.0.44
-- PHP Version: 8.3.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
--

-- --------------------------------------------------------

--
-- Table structure for table `alerts`
--

CREATE TABLE `alerts` (
  `id` varchar(100) NOT NULL,
  `rule_name` varchar(100) NOT NULL,
  `severity` enum('WARNING','CRITICAL') NOT NULL,
  `affected_resource_type` varchar(50) NOT NULL,
  `affected_resource_id` varchar(36) NOT NULL,
  `message` text NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `alerts`
--

INSERT INTO `alerts` (`id`, `rule_name`, `severity`, `affected_resource_type`, `affected_resource_id`, `message`, `created_at`, `updated_at`) VALUES
('alert_les_drv_test1', 'ใบอนุญาตใกล้หมดอายุ', 'WARNING', 'DRIVER', 'drv_test1', 'ใบอนุญาตของพนักงานขับรถ สมชาย (123456789) จะหมดอายุในวันที่ Mon Apr 13 2026 00:00:00 GMT+0700 (Indochina Time) (ภายใน 30 วัน)', '2026-03-30 15:03:07', '2026-03-30 15:03:06'),
('alert_om_15799461-2b61-11f1-9fa0-f26b147e1cb0', 'เลยกำหนดการซ่อมบำรุง', 'CRITICAL', 'MAINTENANCE', '15799461-2b61-11f1-9fa0-f26b147e1cb0', 'การซ่อมบำรุงสำหรับยานพาหนะ กท-1111 (OIL_CHANGE) วันที่ Wed Mar 18 2026 18:18:59 GMT+0700 (Indochina Time) เลยกำหนดมาแล้วกว่า 3 วัน', '2026-03-30 15:03:07', '2026-03-30 15:03:06'),
('alert_td_trp_003', 'การเดินทางล่าช้ากว่ากำหนด', 'WARNING', 'TRIP', 'trp_003', 'การเดินทาง trp_003 ของรถ 3กก-9999 (คนขับ: Sompong Ngamdee) ใช้เวลาเกิน 150% ของที่คาดไว้ (1935 นาที จากที่คาดไว้ 450 นาที)', '2026-03-30 15:03:07', '2026-03-30 15:03:06'),
('alert_td_trp_007', 'การเดินทางล่าช้ากว่ากำหนด', 'WARNING', 'TRIP', 'trp_007', 'การเดินทาง trp_007 ของรถ 3กก-9999 (คนขับ: Somchai Jaidee) ใช้เวลาเกิน 150% ของที่คาดไว้ (2288 นาที จากที่คาดไว้ 288 นาที)', '2026-03-30 15:03:07', '2026-03-30 15:03:06'),
('alert_vds_veh_001', 'รถยนต์ถึงกำหนดรับบริการ', 'WARNING', 'VEHICLE', 'veh_001', 'ยานพาหนะ กท-1111 มีระยะทาง 50000 กม. เกินกำหนดการรับบริการครั้งต่อไป (45000 กม.)', '2026-03-30 15:03:07', '2026-03-30 15:03:06');

-- --------------------------------------------------------

--
-- Table structure for table `audit_logs`
--

CREATE TABLE `audit_logs` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) DEFAULT NULL,
  `action` varchar(50) NOT NULL,
  `resource_type` varchar(50) NOT NULL,
  `resource_id` varchar(36) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `result` enum('SUCCESS','FAIL') NOT NULL,
  `detail` json DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `audit_logs`
--

INSERT INTO `audit_logs` (`id`, `user_id`, `action`, `resource_type`, `resource_id`, `ip_address`, `result`, `detail`, `created_at`) VALUES
('00c1b33c-a16e-460c-8063-5df35a2f59ff', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 23:49:31'),
('01d0799d-8fa4-4459-9bba-d6a7b69d2556', NULL, 'LOGIN_FAIL', 'AUTH', NULL, '::ffff:172.19.0.1', 'FAIL', '{\"username\": \"admin\"}', '2026-03-29 18:17:22'),
('01e8e8fb-91d3-4008-a873-7d289afdd101', NULL, 'LOGIN_FAIL', 'AUTH', NULL, '::ffff:172.19.0.1', 'FAIL', '{\"username\": \"admin\"}', '2026-03-29 18:18:07'),
('04c432ea-6e5a-4b14-9e04-8ff48a41c82f', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', '1f590283-2b66-11f1-9fa0-f26b147e1cb0', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_004\", \"sequence\": 1, \"new_status\": \"ARRIVED\", \"old_status\": \"PENDING\"}', '2026-03-29 18:58:57'),
('04fe0077-9d96-4c1f-9922-c53e636f69de', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 17:28:48'),
('05c83bd7-f852-451a-82b3-0511590ba756', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 16:45:11'),
('078a7eeb-77bd-4299-9428-df7c4c147d82', NULL, 'LOGIN_SUCCESS', 'AUTH', '69f2b35a-d7cc-4f90-8b70-ab7414405fe0', NULL, 'SUCCESS', '{\"role\": \"DISPATCHER\", \"username\": \"user1\"}', '2026-03-29 16:00:00'),
('07f4a32c-d1f2-44f1-80c1-658aca0e8bad', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'CREATE_TRIP', 'TRIP', 'trp_009', '::ffff:172.19.0.1', 'SUCCESS', '{\"origin\": \"dawd\", \"driver_id\": \"drv_004\", \"vehicle_id\": \"veh_004\", \"destination\": \"awd\", \"checkpoints_count\": 0}', '2026-03-29 19:54:40'),
('0ab19600-5417-41ec-ab7f-ea0b290ab7ed', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', '954740d9-2b65-11f1-9fa0-f26b147e1cb0', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_003\", \"sequence\": 3, \"new_status\": \"DEPARTED\", \"old_status\": \"ARRIVED\"}', '2026-03-29 19:12:52'),
('0b3ee07a-ec61-45ba-9f17-924e1448b229', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'DELETE_TRIP', 'TRIP', 'trp_009', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_009\"}', '2026-03-29 22:37:47'),
('0c2aa002-9c92-4be3-bd9d-4210ee64d9cf', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 18:56:27'),
('0ca3deb7-4914-4889-8f51-d712849566a4', NULL, 'LOGIN_FAIL', 'AUTH', NULL, '::ffff:172.19.0.1', 'FAIL', '{\"username\": \"admin\"}', '2026-03-29 18:17:21'),
('0d9bf270-b3c9-4a5b-b398-0f064734c9da', NULL, 'LOGIN_FAIL', 'AUTH', NULL, '::ffff:172.19.0.1', 'FAIL', '{\"username\": \"any\"}', '2026-03-29 20:50:22'),
('14fbcd53-c41c-4a02-96fa-6da59e9575b6', NULL, 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 15:59:41'),
('15e48be2-1193-453f-a014-db80bd9db19f', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 09:35:39'),
('1a04a426-dc64-401f-a1a7-43377fbc19bb', NULL, 'LOGIN_FAIL', 'AUTH', NULL, '::ffff:172.19.0.1', 'FAIL', '{\"username\": \"admin\"}', '2026-03-29 18:17:06'),
('1ac6b1b2-f7dc-4435-b73f-0d89bf2954e5', NULL, 'LOGIN_FAIL', 'AUTH', NULL, '::ffff:172.19.0.1', 'FAIL', '{\"username\": \"admin\"}', '2026-03-29 18:17:05'),
('1ce0db04-ad00-4acb-b015-d86c2e150c0b', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 11:31:56'),
('1fb2521f-1bda-4b3f-ab7b-439014b6d47b', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 00:51:44'),
('202b205b-4d2f-474a-bba3-b87605786dae', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 14:06:16'),
('20ca6501-9469-4ebb-8595-48681dfd8250', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'CREATE_TRIP', 'TRIP', 'trp_012', '::ffff:172.19.0.1', 'SUCCESS', '{\"origin\": \"Wwarehouse 1\", \"driver_id\": \"drv_005\", \"vehicle_id\": \"veh_003\", \"destination\": \"Warehouse 2\", \"checkpoints_count\": 0}', '2026-03-30 10:35:05'),
('228bb311-536b-4719-96a0-ee2b387eae7d', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 13:49:42'),
('2303a6e5-ee68-4459-aafc-a1f92a09e45c', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', '23d0d76f-fd91-429e-af55-2e9638f9a439', NULL, 'SUCCESS', '{\"trip_id\": \"55218a17-fc7a-453e-a836-8a3c1fb468e6\", \"sequence\": 1, \"new_status\": \"PENDING\", \"old_status\": \"ARRIVED\"}', '2026-03-29 17:14:22'),
('23632b1b-dd33-4116-b33b-abadb0477b9e', NULL, 'LOGIN_FAIL', 'AUTH', NULL, '::ffff:172.19.0.1', 'FAIL', '{\"username\": \"admin\"}', '2026-03-29 18:15:37'),
('2497cddd-a419-43a8-9400-3618d5ab9e49', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', 'chk_001', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_011\", \"sequence\": 1, \"new_status\": \"ARRIVED\", \"old_status\": \"PENDING\"}', '2026-03-30 10:57:25'),
('291c2836-b3e4-4804-8e1a-f50ac75cd840', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'CREATE_VEHICLE', 'VEHICLE', 'veh_007', '::ffff:172.19.0.1', 'SUCCESS', '{\"type\": \"TRUCK\", \"license_plate\": \"awd\"}', '2026-03-29 23:44:27'),
('2a3c0bb4-6a57-4aed-84f2-bf1a19d7a622', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'CREATE_TRIP', 'TRIP', 'trp_011', '::ffff:172.19.0.1', 'SUCCESS', '{\"origin\": \"wda\", \"driver_id\": \"drv_005\", \"vehicle_id\": \"veh_004\", \"destination\": \"wada\", \"checkpoints_count\": 3}', '2026-03-29 22:38:13'),
('2c9bcc15-a281-415b-8855-e63572a61864', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 19:20:42'),
('3197195c-5fe0-42d8-ba64-f007cdc0ace4', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'DELETE_TRIP', 'TRIP', 'trp_008', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_008\"}', '2026-03-29 19:51:46'),
('35f1c9fb-0d62-460a-8c71-9131dc2cade7', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 19:06:13'),
('35fd326f-4390-423d-a74b-da670af5a716', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 19:59:44'),
('380a7060-330d-4f55-a1a5-7c6450a4cd9a', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 00:03:36'),
('3a5d83a4-dfa2-4ab6-a30c-db56292113c4', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 10:26:57'),
('40938a96-928d-4d33-b656-fe194af64eaa', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 11:02:55'),
('41f18a48-8dba-4b8b-a48b-233d4ff44511', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 13:22:27'),
('43e69a57-bb7d-43f9-89b7-4b86a035f2d3', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 09:49:46'),
('4416ca1c-d419-418a-9315-5e5d69c38b16', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', 'c8311163-8576-4adb-81f8-b6a0628ca5c2', NULL, 'SUCCESS', '{\"trip_id\": \"52414744-5c89-4898-aff9-fe815f819d63\", \"sequence\": 1, \"new_status\": \"SKIPPED\", \"old_status\": \"PENDING\"}', '2026-03-29 17:11:54'),
('44a341b6-c6b2-4069-88be-faa2db22aeb1', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 22:30:20'),
('48d132bf-cb36-4e3c-8367-c4c3ff4210f4', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 10:42:42'),
('4aeb2657-aab3-4ec7-9088-287dc4673641', NULL, 'LOGIN_FAIL', 'AUTH', NULL, '::ffff:172.19.0.1', 'FAIL', '{\"username\": \"admin\"}', '2026-03-29 18:17:04'),
('4d3bbff1-0352-4751-afd9-44fb1217a305', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 12:47:34'),
('4decd1bb-655a-47ce-8b64-4e1fcdc42730', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'CREATE_TRIP', 'TRIP', 'trp_012', '::ffff:172.19.0.1', 'SUCCESS', '{\"origin\": \"Bangkok\", \"driver_id\": \"drv_001\", \"vehicle_id\": \"veh_004\", \"destination\": \"Chiang Mai\", \"checkpoints_count\": 1}', '2026-03-30 10:55:25'),
('517a2460-9a3e-4a00-a07b-e0a14b0d46dd', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 12:40:00'),
('567bf23b-9dca-4c79-b939-3149cafad1e2', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', 'chk_004', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_012\", \"sequence\": 1, \"new_status\": \"ARRIVED\", \"old_status\": \"PENDING\"}', '2026-03-30 10:56:57'),
('56e61880-76f0-451d-839e-560aba653c49', '794ea47c-f416-48f9-a9fd-fc4d3fd9fca3', 'LOGIN_SUCCESS', 'AUTH', '794ea47c-f416-48f9-a9fd-fc4d3fd9fca3', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"DISPATCHER\", \"username\": \"user3\"}', '2026-03-30 12:52:38'),
('588f4471-5812-4cc7-8b81-c7cfd322b23a', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'DELETE_VEHICLE', 'VEHICLE', 'veh_007', '::ffff:172.19.0.1', 'SUCCESS', '{\"vehicle_id\": \"veh_007\"}', '2026-03-29 23:42:06'),
('5936ef07-dd3d-4539-b75f-25a4b7d81caa', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', '1f5c884b-2b66-11f1-9fa0-f26b147e1cb0', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_004\", \"sequence\": 2, \"new_status\": \"ARRIVED\", \"old_status\": \"PENDING\"}', '2026-03-29 19:06:24'),
('5cf47ed3-fbad-4ed0-a1f6-3f46f5c36f93', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 23:35:24'),
('5d568dfe-c5f0-4fc2-a0e8-71b6ca41a933', '69f2b35a-d7cc-4f90-8b70-ab7414405fe0', 'LOGIN_SUCCESS', 'AUTH', '69f2b35a-d7cc-4f90-8b70-ab7414405fe0', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"DISPATCHER\", \"username\": \"user1\"}', '2026-03-30 12:48:43'),
('5db1f2c0-f21a-4f6a-addd-b3d1fb6c22a7', NULL, 'LOGIN_FAIL', 'AUTH', NULL, '::ffff:172.19.0.1', 'FAIL', '{\"username\": \"admin\"}', '2026-03-29 18:18:06'),
('5dd8f07f-9aab-4dc9-9607-4cea1b61e79a', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 10:48:48'),
('5eae464e-eff8-43b0-86ac-dc75ffe98da2', '69f2b35a-d7cc-4f90-8b70-ab7414405fe0', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 11:07:32'),
('5faa9678-a2e7-4968-9859-34404a12a608', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', '1f5c884b-2b66-11f1-9fa0-f26b147e1cb0', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_004\", \"sequence\": 2, \"new_status\": \"DEPARTED\", \"old_status\": \"ARRIVED\"}', '2026-03-29 19:07:37'),
('61534d41-7f0e-4d77-9915-6bf968381d3b', NULL, 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 15:57:56'),
('63a15193-2c72-4434-b915-19501808ba9d', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 10:32:15'),
('67d2deb9-3c12-4e8d-bd1d-8ece226a8284', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 15:20:47'),
('6c1aa843-2dd3-42b3-9199-2f60c67d9724', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'ASSIGN_DRIVER', 'VEHICLE', 'veh_004', '::ffff:172.19.0.1', 'SUCCESS', '{\"new_driver_id\": \"drv_test1\", \"old_driver_id\": \"drv_009\"}', '2026-03-29 19:32:51'),
('6cd1dfa5-0144-4d23-8001-368a34d7ed80', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'CREATE_TRIP', 'TRIP', 'trp_012', '::ffff:172.19.0.1', 'SUCCESS', '{\"origin\": \"loo\", \"driver_id\": \"drv_004\", \"vehicle_id\": \"veh_003\", \"destination\": \"loom\", \"checkpoints_count\": 0}', '2026-03-30 10:33:15'),
('6ed37975-c602-430f-97ea-eb7b5b80a6b6', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', '7c261392-82fb-44b9-aa52-c8310f4451a3', NULL, 'SUCCESS', '{\"trip_id\": \"8a85f8ac-216f-4164-9a0f-6559f12e4394\", \"sequence\": 1, \"new_status\": \"ARRIVED\", \"old_status\": \"PENDING\"}', '2026-03-29 17:07:35'),
('6f31de21-6ba4-4943-b72b-67e99b8ea7ac', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 12:25:43'),
('70219c52-ca94-4207-8d2e-0a5330de1295', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 10:59:52'),
('72a6e39f-a183-4824-a5fe-f04cc767b0fa', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 18:10:45'),
('75015b5e-ed8c-4dc2-9395-c86d18739ff2', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'CREATE_VEHICLE', 'VEHICLE', 'veh_008', '::ffff:172.19.0.1', 'SUCCESS', '{\"type\": \"MOTORCYCLE\", \"license_plate\": \"กท-1449\"}', '2026-03-30 12:43:59'),
('7501a6a4-f078-4f8f-8ad6-e21f05f4c59c', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', '1f590283-2b66-11f1-9fa0-f26b147e1cb0', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_004\", \"sequence\": 1, \"new_status\": \"DEPARTED\", \"old_status\": \"ARRIVED\"}', '2026-03-29 19:05:57'),
('7948302c-15a4-416f-8737-d8efbeee2af0', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 13:20:06'),
('79b04c97-0104-4788-9099-9208de180d37', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 19:45:23'),
('7b3f4c7b-cda0-4f68-bc07-64ee089b5bf2', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 14:55:40'),
('7ba50182-3f8f-4b6e-93a9-f5e7697bde96', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 18:37:37'),
('80b4edfe-4140-46bc-a1f8-663195302239', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 19:28:14'),
('81d11e65-d71a-46de-8d6c-1548183835e8', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 00:49:03'),
('82697b95-e0aa-4c6e-a7bf-143d9fde4c34', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_DRIVER', 'DRIVER', 'drv_004', '::ffff:172.19.0.1', 'SUCCESS', '{\"name\": \"Anurak Petchthong\", \"status\": \"ACTIVE\"}', '2026-03-30 11:01:03'),
('84fe9385-4b89-4574-a920-8bfd2e2df04c', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 18:52:04'),
('852e4161-b374-47bf-a974-e1541fb4bd89', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 13:31:01'),
('8ba5e4b8-a3d6-4382-bb8f-6a4329dbb3a5', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', '1f5f2b38-2b66-11f1-9fa0-f26b147e1cb0', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_004\", \"sequence\": 3, \"new_status\": \"ARRIVED\", \"old_status\": \"PENDING\"}', '2026-03-29 19:08:00'),
('8d393e3c-0187-4569-8599-852a107db528', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 11:27:08'),
('8e9cfac8-d752-40fd-ade7-ca8c6dd4c0ba', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', '954740d9-2b65-11f1-9fa0-f26b147e1cb0', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_003\", \"sequence\": 3, \"new_status\": \"DEPARTED\", \"old_status\": \"ARRIVED\"}', '2026-03-29 18:52:46'),
('8eb65d04-5b11-4ff8-b93e-6576f8fbfbed', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', '23d0d76f-fd91-429e-af55-2e9638f9a439', NULL, 'SUCCESS', '{\"trip_id\": \"55218a17-fc7a-453e-a836-8a3c1fb468e6\", \"sequence\": 1, \"new_status\": \"ARRIVED\", \"old_status\": \"PENDING\"}', '2026-03-29 17:14:10'),
('919bab1b-341a-4bef-bc7a-e8c52002081f', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'CREATE_TRIP', 'TRIP', 'trp_010', '::ffff:172.19.0.1', 'SUCCESS', '{\"origin\": \"dawd\", \"driver_id\": \"drv_005\", \"vehicle_id\": \"veh_004\", \"destination\": \"awda\", \"checkpoints_count\": 0}', '2026-03-29 20:02:18'),
('919f452f-31aa-4c31-8698-d546df92807e', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'CREATE_VEHICLE', 'VEHICLE', 'veh_004', NULL, 'SUCCESS', '{\"type\": \"TRUCK\", \"license_plate\": \"กท-1445\"}', '2026-03-29 16:01:03'),
('938c1220-0616-4eea-90b4-28a909f823ea', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_VEHICLE_STATUS', 'VEHICLE', 'veh_test1', NULL, 'SUCCESS', '{\"new_status\": \"MAINTENANCE\", \"old_status\": \"IDLE\"}', '2026-03-29 10:38:41'),
('9391fa58-6888-47a6-8592-d90a52e09667', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_TRIP_STATUS', 'TRIP', 'trp_012', '::ffff:172.19.0.1', 'SUCCESS', '{\"new_status\": \"IN_PROGRESS\", \"old_status\": \"IN_PROGRESS\"}', '2026-03-30 10:48:38'),
('97c866e8-7a36-4ea8-b7a8-95d797c88165', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_DRIVER', 'DRIVER', 'drv_009', '::ffff:172.19.0.1', 'SUCCESS', '{\"name\": \"Fahsaai Jaimun\", \"status\": \"SUSPENDED\"}', '2026-03-29 19:31:44'),
('97f45c7b-5b7c-40f8-a1d9-db104e8ca725', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '69f2b35a-d7cc-4f90-8b70-ab7414405fe0', NULL, 'SUCCESS', '{\"role\": \"DISPATCHER\", \"username\": \"user1\"}', '2026-03-29 11:03:11'),
('998890e3-3c00-4992-99a1-43cc414187df', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'DELETE_TRIP', 'TRIP', 'trp_012', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_012\"}', '2026-03-30 10:49:37'),
('9a78f2c4-8bfc-439c-b521-df72713ea7eb', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_TRIP_STATUS', 'TRIP', 'trp_011', '::ffff:172.19.0.1', 'SUCCESS', '{\"new_status\": \"CANCELLED\", \"old_status\": \"IN_PROGRESS\"}', '2026-03-29 23:13:01'),
('9c75cb0d-4b26-4980-be0b-0de9e71677e5', '69f2b35a-d7cc-4f90-8b70-ab7414405fe0', 'LOGIN_SUCCESS', 'AUTH', '69f2b35a-d7cc-4f90-8b70-ab7414405fe0', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"DISPATCHER\", \"username\": \"user1\"}', '2026-03-30 10:04:01'),
('9efc962a-72bc-44a0-9fad-9cbcdb3909c5', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 12:09:52'),
('a12a4cc7-34f8-4478-8817-08201e5dd428', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 20:52:35'),
('a21bc303-aa0a-41c1-bcc4-19499bf2d234', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 17:08:50'),
('a4ac17f8-840d-406e-a28a-f5aec6f8b7e0', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 17:03:24'),
('a87275f8-6ca1-4afd-96f4-2eb6da5d9521', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 22:09:31'),
('ab2132f6-715b-42ac-8000-f1b12895e11d', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 17:35:02'),
('af5040ef-de1f-4530-ac8c-648625c69603', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 10:04:32'),
('b1a9a4d4-7d24-4b15-a280-157533abd13a', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 13:23:59'),
('b2bba6b6-fa63-468d-83fe-285449717815', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 10:19:34'),
('c009a40d-e2cd-4e0a-a508-105db859a016', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 14:06:00'),
('c2f73a7f-c134-43d0-933f-d94c55608efb', NULL, 'LOGIN_FAIL', 'AUTH', NULL, '::ffff:172.19.0.1', 'FAIL', '{\"username\": \"admin\"}', '2026-03-29 18:17:44'),
('c690f80b-b30a-48c9-8e86-433b72b4fb11', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', '23d0d76f-fd91-429e-af55-2e9638f9a439', NULL, 'SUCCESS', '{\"trip_id\": \"55218a17-fc7a-453e-a836-8a3c1fb468e6\", \"sequence\": 1, \"new_status\": \"SKIPPED\", \"old_status\": \"PENDING\"}', '2026-03-29 17:12:40'),
('cbbb3e6f-f550-45af-a079-1e0fb6914848', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 13:12:26'),
('cbe793d5-0b73-48c3-a800-7be3e6612165', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 12:55:57'),
('cc6e7302-14de-4867-a4fe-60d995135315', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_FAIL', 'AUTH', NULL, NULL, 'FAIL', '{\"username\": \"admin\"}', '2026-03-29 10:27:13'),
('ce5c9417-338f-42ad-b969-7048b66cbd4b', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 17:05:39'),
('d2137f16-48b7-4348-ae82-5bc091015e29', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 16:04:55'),
('d31dbcb5-7dc5-46b5-8934-7a9dc9047b23', NULL, 'LOGIN_FAIL', 'AUTH', NULL, '::ffff:172.19.0.1', 'FAIL', '{\"username\": \"admin\"}', '2026-03-29 18:17:43'),
('d3ce6340-df7b-44ec-adfc-bd5f2ec2365c', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'CREATE_VEHICLE', 'VEHICLE', 'veh_007', '::ffff:172.19.0.1', 'SUCCESS', '{\"type\": \"TRUCK\", \"license_plate\": \"awd\"}', '2026-03-29 23:41:46'),
('d6c3d35f-18f7-485d-b8ff-20bd32d6a113', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'DELETE_TRIP', 'TRIP', 'trp_006', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_006\"}', '2026-03-29 23:18:11'),
('d72c8db7-9cad-4b3a-9775-620af3d7a081', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 16:07:10'),
('db1afa2b-acfa-44c0-b10f-e6b0956fc3a5', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_VEHICLE_STATUS', 'VEHICLE', 'veh_001', '::ffff:172.19.0.1', 'SUCCESS', '{\"new_status\": \"ACTIVE\", \"old_status\": \"MAINTENANCE\"}', '2026-03-30 10:53:24'),
('db1ea49b-a9ee-4569-8d79-72da4ac29e6a', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_TRIP_STATUS', 'TRIP', 'trp_012', '::ffff:172.19.0.1', 'SUCCESS', '{\"new_status\": \"SCHEDULED\", \"old_status\": \"IN_PROGRESS\"}', '2026-03-30 10:49:27'),
('df93d022-559f-49a5-b7b5-26cd4b7a936b', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 10:34:20'),
('e1373d7e-ac0a-4e4b-b3dc-6c76a2c9ab11', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'DELETE_TRIP', 'TRIP', 'trp_012', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_012\"}', '2026-03-30 10:34:35'),
('e21cb4e1-1254-4dc5-a0dd-524662595191', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_VEHICLE_STATUS', 'VEHICLE', 'veh_004', NULL, 'SUCCESS', '{\"new_status\": \"IDLE\", \"old_status\": \"ACTIVE\"}', '2026-03-29 16:03:39'),
('e3e8c7aa-29b5-4c2f-b6f4-002f238e756b', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 23:02:37'),
('e546e670-1d65-43e5-849d-93ff7670dbd3', NULL, 'LOGIN_FAIL', 'AUTH', NULL, '::ffff:172.19.0.1', 'FAIL', '{\"username\": \"admin\"}', '2026-03-29 18:17:07'),
('e6d67295-5a06-4c08-a4ab-c27100892d46', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 17:13:15'),
('e9c680c7-64e3-44c6-9a83-5b01ef11566d', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 13:30:13'),
('ea4e51f0-7683-404a-a37f-348afe2f5a3f', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 13:00:58'),
('edb9ebe0-319b-45cb-9bce-f051b694e330', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 23:33:46'),
('ee2a9415-be61-48a2-9f10-512af1dab5a0', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_VEHICLE_DETAILS', 'VEHICLE', 'veh_007', '::ffff:172.19.0.1', 'SUCCESS', '{\"type\": \"TRUCK\", \"license_plate\": \"awd\"}', '2026-03-29 23:58:05'),
('ee74f099-98fb-4538-8459-ccb5f452dcb5', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', '1f5f2b38-2b66-11f1-9fa0-f26b147e1cb0', '::ffff:172.19.0.1', 'SUCCESS', '{\"trip_id\": \"trp_004\", \"sequence\": 3, \"new_status\": \"DEPARTED\", \"old_status\": \"ARRIVED\"}', '2026-03-29 19:14:02'),
('eeca82eb-2942-4d5f-890f-3e6f8b792975', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 14:40:06'),
('f04a9751-86d1-4416-b822-eabcc0cba099', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-30 13:46:29'),
('f3885964-370f-476c-a624-3a1681904ec6', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'UPDATE_DRIVER', 'DRIVER', 'drv_004', '::ffff:172.19.0.1', 'SUCCESS', '{\"name\": \"Anurak Petchthong\", \"status\": \"ACTIVE\"}', '2026-03-30 11:02:30'),
('f508c7eb-2b4d-413d-a28b-b2445bfa51a6', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 17:56:40'),
('f6360b43-91cb-414a-9341-c982360ae419', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', NULL, 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 17:18:39'),
('fbb84f99-b627-47ad-8289-24415ae76171', '92f5b148-83ee-44ee-9a23-77023d5f5440', 'LOGIN_SUCCESS', 'AUTH', '92f5b148-83ee-44ee-9a23-77023d5f5440', '::ffff:172.19.0.1', 'SUCCESS', '{\"role\": \"ADMIN\", \"username\": \"admin\"}', '2026-03-29 23:16:44');

-- --------------------------------------------------------

--
-- Table structure for table `checkpoints`
--

CREATE TABLE `checkpoints` (
  `id` varchar(36) NOT NULL,
  `trip_id` varchar(36) NOT NULL,
  `sequence` tinyint NOT NULL,
  `status` enum('PENDING','ARRIVED','DEPARTED','SKIPPED') NOT NULL DEFAULT 'PENDING',
  `location_name` varchar(100) NOT NULL,
  `latitude` decimal(9,6) DEFAULT NULL,
  `longitude` decimal(9,6) DEFAULT NULL,
  `purpose` enum('FUEL','REST','DELIVERY','PICKUP','INSPECTION') DEFAULT NULL,
  `notes` text,
  `arrived_at` datetime DEFAULT NULL,
  `departed_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `checkpoints`
--

INSERT INTO `checkpoints` (`id`, `trip_id`, `sequence`, `status`, `location_name`, `latitude`, `longitude`, `purpose`, `notes`, `arrived_at`, `departed_at`, `created_at`) VALUES
('1f590283-2b66-11f1-9fa0-f26b147e1cb0', 'trp_004', 1, 'DEPARTED', 'ศูนย์กระจายสินค้าภาคกลาง อยุธยา', NULL, NULL, 'PICKUP', 'รับสินค้าแช่แข็งเพิ่มเติม 500 กิโลกรัมก่อนขึ้นเหนือ', '2026-03-29 18:58:57', '2026-03-29 19:05:57', '2026-03-29 18:55:03'),
('1f5c884b-2b66-11f1-9fa0-f26b147e1cb0', 'trp_004', 2, 'DEPARTED', 'สถานีตรวจสอบน้ำหนัก นครสวรรค์', NULL, NULL, 'INSPECTION', 'ตรวจสอบเอกสารและน้ำหนักบรรทุก', '2026-03-29 19:06:24', '2026-03-29 19:07:37', '2026-03-29 18:55:03'),
('1f5f2b38-2b66-11f1-9fa0-f26b147e1cb0', 'trp_004', 3, 'DEPARTED', 'ปั๊ม ปตท. พิษณุโลก', NULL, NULL, 'FUEL', 'ต้องเติมน้ำมันดีเซลเต็มถัง เพื่อให้เพียงพอวิ่งข้ามเขา', '2026-03-29 19:08:00', '2026-03-29 19:14:02', '2026-03-29 18:55:03'),
('1f624428-2b66-11f1-9fa0-f26b147e1cb0', 'trp_004', 4, 'DEPARTED', 'จุดพักรถ ลำปาง', NULL, NULL, 'REST', 'พักเบรกคนขับ 1 ชั่วโมงหลังจากขับข้ามเขา', '2026-03-29 23:18:58', '2026-03-29 23:19:00', '2026-03-29 18:55:03'),
('1f65860d-2b66-11f1-9fa0-f26b147e1cb0', 'trp_004', 5, 'DEPARTED', 'คลังสินค้าปลายทาง เชียงใหม่', NULL, NULL, 'DELIVERY', 'เตรียมขนส่งมอบสินค้าและเซ็นรับ', '2026-03-29 23:19:01', '2026-03-29 23:19:02', '2026-03-29 18:55:03'),
('9541a2a1-2b65-11f1-9fa0-f26b147e1cb0', 'trp_003', 1, 'DEPARTED', 'ปั๊ม ปตท. วังน้อย', NULL, NULL, 'FUEL', 'เติมน้ำมันเต็มถังและเช็คลมยาง', '2026-03-29 07:51:12', '2026-03-29 08:51:12', '2026-03-29 18:51:12'),
('95448c70-2b65-11f1-9fa0-f26b147e1cb0', 'trp_003', 2, 'DEPARTED', 'สถานีตรวจสอบน้ำหนัก ปากช่อง', NULL, NULL, 'INSPECTION', 'น้ำหนักผ่านเกณฑ์ปกติ', '2026-03-29 10:51:12', '2026-03-29 11:51:12', '2026-03-29 18:51:12'),
('954740d9-2b65-11f1-9fa0-f26b147e1cb0', 'trp_003', 3, 'DEPARTED', 'จุดพักรถ ลำตะคอง', NULL, NULL, 'REST', 'คนขับแจ้งว่ารถมีปัญหาความร้อน กำลังรอช่างจากศูนย์', '2026-03-29 12:51:12', '2026-03-29 19:12:52', '2026-03-29 18:51:12'),
('chk_001', 'trp_011', 1, 'ARRIVED', 'Lo1', NULL, NULL, 'DELIVERY', NULL, '2026-03-30 10:57:25', NULL, '2026-03-29 22:38:13'),
('chk_002', 'trp_011', 2, 'PENDING', 'Lo2', NULL, NULL, 'DELIVERY', NULL, NULL, NULL, '2026-03-29 22:38:13'),
('chk_003', 'trp_011', 3, 'PENDING', 'Lo3', NULL, NULL, 'DELIVERY', NULL, NULL, NULL, '2026-03-29 22:38:13'),
('chk_004', 'trp_012', 1, 'ARRIVED', 'Nakhon Sawan', 15.690000, 100.120000, 'FUEL', NULL, '2026-03-30 10:56:57', NULL, '2026-03-30 10:55:25');

-- --------------------------------------------------------

--
-- Table structure for table `drivers`
--

CREATE TABLE `drivers` (
  `id` varchar(36) NOT NULL,
  `name` varchar(100) NOT NULL,
  `license_number` varchar(50) NOT NULL,
  `license_expires_at` date NOT NULL,
  `phone` varchar(20) NOT NULL,
  `status` enum('ACTIVE','INACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `drivers`
--

INSERT INTO `drivers` (`id`, `name`, `license_number`, `license_expires_at`, `phone`, `status`, `created_at`, `updated_at`) VALUES
('drv_001', 'Somchai Jaidee', 'D-12345678', '2028-12-31', '0812345678', 'ACTIVE', '2026-03-28 21:23:19', '2026-03-28 21:23:19'),
('drv_002', 'Somsak Rakthai', 'D-87654321', '2025-06-30', '0898765432', 'INACTIVE', '2026-03-28 21:23:19', '2026-03-28 21:23:19'),
('drv_003', 'Sompong Ngamdee', 'D-11223344', '2024-01-15', '0855555555', 'SUSPENDED', '2026-03-28 21:23:19', '2026-03-28 21:23:19'),
('drv_004', 'Anurak Petchthong', 'D-55667788', '2029-05-18', '0811512244', 'ACTIVE', '2026-03-29 00:40:35', '2026-03-30 11:02:30'),
('drv_005', 'Boonmee Srisuk', 'D-99887766', '2027-11-15', '0823334444', 'ACTIVE', '2026-03-29 00:40:35', '2026-03-29 00:40:35'),
('drv_006', 'Chaiwat Rungruang', 'D-10203040', '2026-08-10', '0835556666', 'ACTIVE', '2026-03-29 00:40:35', '2026-03-29 00:40:35'),
('drv_007', 'Darunee Rakdee', 'D-50607080', '2028-02-28', '0847778888', 'INACTIVE', '2026-03-29 00:40:35', '2026-03-29 00:40:35'),
('drv_008', 'Ekasit Wongyai', 'D-13579246', '2025-10-05', '0859990000', 'SUSPENDED', '2026-03-29 00:40:35', '2026-03-29 00:40:35'),
('drv_010', 'Kittisak Manprasert', 'D-98765432', '2030-01-01', '0876543210', 'ACTIVE', '2026-03-29 00:40:35', '2026-03-29 00:40:35'),
('drv_test1', 'สมชาย', '123456789', '2026-04-13', '0812345678', 'ACTIVE', '2026-03-29 02:29:41', '2026-03-29 02:29:41'),
('drv_test2', 'สมศักดิ์', '987654321', '2027-03-29', '0899999999', 'ACTIVE', '2026-03-29 02:29:41', '2026-03-29 02:29:41');

-- --------------------------------------------------------

--
-- Table structure for table `maintenance`
--

CREATE TABLE `maintenance` (
  `id` varchar(36) NOT NULL,
  `vehicle_id` varchar(36) NOT NULL,
  `status` enum('SCHEDULED','IN_PROGRESS','COMPLETED','OVERDUE') NOT NULL DEFAULT 'SCHEDULED',
  `type` enum('OIL_CHANGE','TIRE','BRAKE','ENGINE','INSPECTION','REPAIR') NOT NULL,
  `scheduled_at` datetime NOT NULL,
  `completed_at` datetime DEFAULT NULL,
  `mileage_at_service` int DEFAULT NULL,
  `technician` varchar(100) DEFAULT NULL,
  `cost_thb` decimal(10,2) DEFAULT NULL,
  `notes` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `maintenance`
--

INSERT INTO `maintenance` (`id`, `vehicle_id`, `status`, `type`, `scheduled_at`, `completed_at`, `mileage_at_service`, `technician`, `cost_thb`, `notes`, `created_at`, `updated_at`) VALUES
('15799461-2b61-11f1-9fa0-f26b147e1cb0', 'veh_001', 'SCHEDULED', 'OIL_CHANGE', '2026-03-18 18:18:59', NULL, NULL, 'ช่างสมชาย', NULL, 'เปลี่ยนถ่ายน้ำมันเครื่องและไส้กรองตามระยะ', '2026-03-29 18:18:59', '2026-03-30 12:37:46'),
('157c0859-2b61-11f1-9fa0-f26b147e1cb0', 'veh_002', 'IN_PROGRESS', 'ENGINE', '2026-03-28 18:18:59', NULL, NULL, 'ช่างบอล', NULL, 'เช็คไฟเครื่องโชว์ และระบบหล่อเย็นกำลังแก้ไข', '2026-03-29 18:18:59', '2026-03-29 18:18:59'),
('157ee7e0-2b61-11f1-9fa0-f26b147e1cb0', 'veh_003', 'COMPLETED', 'TIRE', '2026-03-19 18:18:59', '2026-03-20 18:18:59', 45000, 'ช่างเทพ', 12500.00, 'เปลี่ยนยางใหม่ 4 เส้นและตั้งศูนย์ถ่วงล้อ', '2026-03-29 18:18:59', '2026-03-29 18:18:59'),
('1581a972-2b61-11f1-9fa0-f26b147e1cb0', 'veh_004', 'OVERDUE', 'INSPECTION', '2026-03-24 18:18:59', NULL, NULL, 'ช่างเอก', NULL, 'นัดตรวจเช็คสภาพรถประจำปี แต่คนขับยังไม่นำรถเข้ามา', '2026-03-29 18:18:59', '2026-03-29 18:18:59');

-- --------------------------------------------------------

--
-- Table structure for table `maintenance_parts`
--

CREATE TABLE `maintenance_parts` (
  `id` varchar(36) NOT NULL,
  `maintenance_id` varchar(36) NOT NULL,
  `part_name` varchar(100) NOT NULL,
  `part_number` varchar(50) DEFAULT NULL,
  `quantity` tinyint NOT NULL DEFAULT '1',
  `cost_thb` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `trips`
--

CREATE TABLE `trips` (
  `id` varchar(36) NOT NULL,
  `vehicle_id` varchar(36) NOT NULL,
  `driver_id` varchar(36) NOT NULL,
  `status` enum('SCHEDULED','IN_PROGRESS','COMPLETED','CANCELLED') NOT NULL DEFAULT 'SCHEDULED',
  `origin` varchar(100) NOT NULL,
  `destination` varchar(100) NOT NULL,
  `distance_km` decimal(8,2) DEFAULT NULL,
  `cargo_type` enum('GENERAL','FRAGILE','HAZARDOUS','REFRIGERATED') DEFAULT NULL,
  `cargo_weight_kg` decimal(8,2) DEFAULT NULL,
  `started_at` datetime DEFAULT NULL,
  `ended_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `trips`
--

INSERT INTO `trips` (`id`, `vehicle_id`, `driver_id`, `status`, `origin`, `destination`, `distance_km`, `cargo_type`, `cargo_weight_kg`, `started_at`, `ended_at`, `created_at`, `updated_at`) VALUES
('trp_001', 'veh_003', 'drv_004', 'COMPLETED', 'Warehouse A', 'Warehouse B', 244.00, 'GENERAL', NULL, NULL, NULL, '2026-03-29 18:46:10', '2026-03-29 19:19:35'),
('trp_002', 'veh_002', 'drv_002', 'COMPLETED', 'ระยอง', 'ชลบุรี', 120.50, 'HAZARDOUS', 3500.00, '2026-03-28 14:48:22', '2026-03-28 18:48:22', '2026-03-28 18:48:22', '2026-03-29 18:48:22'),
('trp_003', 'veh_003', 'drv_003', 'IN_PROGRESS', 'กรุงเทพ', 'นครราชสีมา', 250.00, 'GENERAL', 5000.00, '2026-03-29 06:48:22', NULL, '2026-03-29 18:48:22', '2026-03-29 18:48:22'),
('trp_004', 'veh_004', 'drv_004', 'IN_PROGRESS', 'สมุทรปราการ', 'เชียงใหม่', 710.00, 'REFRIGERATED', 2000.00, NULL, NULL, '2026-03-29 18:48:22', '2026-03-29 19:05:39'),
('trp_005', 'veh_005', 'drv_005', 'COMPLETED', 'ขอนแก่น', 'อุดรธานี', 115.00, 'FRAGILE', 800.00, '2026-03-26 12:48:22', '2026-03-26 14:48:22', '2026-03-26 18:48:22', '2026-03-29 18:48:22'),
('trp_007', 'veh_003', 'drv_001', 'IN_PROGRESS', 'Rayong', 'Bangkok Port', 160.00, 'HAZARDOUS', NULL, '2026-03-29 00:55:34', '2026-03-28 04:37:16', '2026-03-29 00:37:16', '2026-03-29 18:49:59'),
('trp_008', 'veh_004', 'drv_005', 'SCHEDULED', 'ฟไก', 'ไฟไฟก', NULL, 'GENERAL', NULL, NULL, NULL, '2026-03-29 19:52:21', '2026-03-29 19:52:21'),
('trp_010', 'veh_004', 'drv_005', 'SCHEDULED', 'dawd', 'awda', 232.00, 'GENERAL', NULL, NULL, NULL, '2026-03-29 20:02:18', '2026-03-29 20:02:18'),
('trp_011', 'veh_004', 'drv_005', 'CANCELLED', 'wda', 'wada', 2323.00, 'GENERAL', NULL, NULL, '2026-03-29 23:13:01', '2026-03-29 22:38:13', '2026-03-29 23:13:01'),
('trp_012', 'veh_004', 'drv_001', 'SCHEDULED', 'Bangkok', 'Chiang Mai', 700.00, 'GENERAL', 5000.00, NULL, NULL, '2026-03-30 10:55:25', '2026-03-30 10:55:25');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` varchar(36) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('DISPATCHER','ADMIN') NOT NULL DEFAULT 'DISPATCHER',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password_hash`, `role`, `created_at`) VALUES
('3a8e175c-85d8-4f53-8d8a-735a1e96dbb4', 'user2', '$2b$10$7vJdcyzIIXNn9nmXPLf/2ejQ0P2oj9a506GG4RfmnPp.rBB21nMbu', 'DISPATCHER', '2026-03-28 20:10:49'),
('4b6271e4-b5a5-4887-b2b5-117a8a32b5bb', 'admin55', '$2b$10$tExBCaY4s1F7UDi.e3x9eeDtfOXnuEwTaP.6PwvW/68kTdz4EUWXy', 'DISPATCHER', '2026-03-28 22:58:10'),
('57e085c6-e9b8-400f-8d05-70d9ea2f01f2', 'test', '$2b$10$e5kIi2ze2yAaYU9cpKm7F.4TC6KVQrW.oKusLYzT0DqBKkCu7GoTG', 'DISPATCHER', '2026-03-29 02:30:46'),
('69f2b35a-d7cc-4f90-8b70-ab7414405fe0', 'user1', '$2b$10$r8gM572yHMHXT9ASFH5gpOUzIw2nbmcjx3Wh6Wu6ox7dO6bZPQxa.', 'DISPATCHER', '2026-03-28 13:07:08'),
('794ea47c-f416-48f9-a9fd-fc4d3fd9fca3', 'user3', '$2b$10$mgI2VTSGYS0QfpDAlvxFy.y7eboDJw8KAXW.ZIN/WqMhuWSo3yNrW', 'DISPATCHER', '2026-03-30 12:51:26'),
('92f5b148-83ee-44ee-9a23-77023d5f5440', 'admin', '$2b$10$57zybvCWPmm188x8lkSMy.2FWwppAx7FVaCayGkHuC0T6UIv2bQWu', 'ADMIN', '2026-03-28 21:38:07'),
('aac86dd8-e838-4503-b2d2-46f3cabce1f3', 'admin11', '$2b$10$ZDs5My6LVCWZ409.quliTuZ16zapRmVug81qfTxv47pW89iFG1txC', 'DISPATCHER', '2026-03-29 00:44:30');

-- --------------------------------------------------------

--
-- Table structure for table `vehicles`
--

CREATE TABLE `vehicles` (
  `id` varchar(36) NOT NULL,
  `license_plate` varchar(20) NOT NULL,
  `type` enum('TRUCK','VAN','MOTORCYCLE','PICKUP') NOT NULL,
  `status` enum('ACTIVE','IDLE','MAINTENANCE','RETIRED') NOT NULL DEFAULT 'IDLE',
  `driver_id` varchar(36) DEFAULT NULL,
  `brand` varchar(50) DEFAULT NULL,
  `model` varchar(50) DEFAULT NULL,
  `year` smallint DEFAULT NULL,
  `fuel_type` enum('DIESEL','GASOLINE','ELECTRIC','HYBRID') DEFAULT NULL,
  `mileage_km` int NOT NULL DEFAULT '0',
  `last_service_km` int DEFAULT NULL,
  `next_service_km` int DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `vehicles`
--

INSERT INTO `vehicles` (`id`, `license_plate`, `type`, `status`, `driver_id`, `brand`, `model`, `year`, `fuel_type`, `mileage_km`, `last_service_km`, `next_service_km`, `created_at`, `updated_at`) VALUES
('veh_001', 'กท-1111', 'TRUCK', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 50000, NULL, 45000, '2026-03-29 02:29:40', '2026-03-30 10:53:24'),
('veh_002', '2ฒฮ-5678', 'VAN', 'MAINTENANCE', 'drv_001', 'Toyota', 'Hiace', 2023, 'DIESEL', 50000, 45000, 60000, '2026-03-28 21:23:52', '2026-03-28 22:43:28'),
('veh_003', '3กก-9999', 'PICKUP', 'IDLE', 'drv_001', NULL, NULL, NULL, NULL, 1020, NULL, NULL, '2026-03-28 21:12:00', '2026-03-30 10:44:22'),
('veh_004', 'กท-1445', 'TRUCK', 'IDLE', 'drv_test1', 'Isuzu', 'Mu-x', 2020, 'DIESEL', 15778, NULL, 30000, '2026-03-29 16:01:03', '2026-03-29 23:13:01'),
('veh_005', 'กท-2222', 'VAN', 'MAINTENANCE', NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-29 02:29:40', '2026-03-29 16:57:16'),
('veh_006', 'กท-3333', 'PICKUP', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-29 02:29:41', '2026-03-29 16:57:23'),
('veh_007', 'awd', 'TRUCK', 'IDLE', NULL, 'daww', NULL, NULL, 'DIESEL', 0, NULL, NULL, '2026-03-29 23:44:27', '2026-03-29 23:58:05'),
('veh_008', 'กท-1449', 'MOTORCYCLE', 'IDLE', NULL, NULL, NULL, NULL, 'DIESEL', 0, NULL, NULL, '2026-03-30 12:43:59', '2026-03-30 12:43:59');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `alerts`
--
ALTER TABLE `alerts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_rule_resource` (`rule_name`,`affected_resource_id`);

--
-- Indexes for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_audit_user` (`user_id`),
  ADD KEY `idx_audit_created` (`created_at`);

--
-- Indexes for table `checkpoints`
--
ALTER TABLE `checkpoints`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_trip_sequence` (`trip_id`,`sequence`),
  ADD KEY `idx_checkpoints_trip` (`trip_id`);

--
-- Indexes for table `drivers`
--
ALTER TABLE `drivers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `license_number` (`license_number`);

--
-- Indexes for table `maintenance`
--
ALTER TABLE `maintenance`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_maintenance_vehicle` (`vehicle_id`),
  ADD KEY `idx_maintenance_status` (`status`),
  ADD KEY `idx_maintenance_scheduled` (`scheduled_at`);

--
-- Indexes for table `maintenance_parts`
--
ALTER TABLE `maintenance_parts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `maintenance_id` (`maintenance_id`);

--
-- Indexes for table `trips`
--
ALTER TABLE `trips`
  ADD PRIMARY KEY (`id`),
  ADD KEY `driver_id` (`driver_id`),
  ADD KEY `idx_trips_vehicle` (`vehicle_id`),
  ADD KEY `idx_trips_status` (`status`),
  ADD KEY `idx_trips_started` (`started_at`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `vehicles`
--
ALTER TABLE `vehicles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `license_plate` (`license_plate`),
  ADD KEY `idx_vehicles_status` (`status`),
  ADD KEY `idx_vehicles_driver` (`driver_id`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `checkpoints`
--
ALTER TABLE `checkpoints`
  ADD CONSTRAINT `checkpoints_ibfk_1` FOREIGN KEY (`trip_id`) REFERENCES `trips` (`id`);

--
-- Constraints for table `maintenance`
--
ALTER TABLE `maintenance`
  ADD CONSTRAINT `maintenance_ibfk_1` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`);

--
-- Constraints for table `maintenance_parts`
--
ALTER TABLE `maintenance_parts`
  ADD CONSTRAINT `maintenance_parts_ibfk_1` FOREIGN KEY (`maintenance_id`) REFERENCES `maintenance` (`id`);

--
-- Constraints for table `trips`
--
ALTER TABLE `trips`
  ADD CONSTRAINT `trips_ibfk_1` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`),
  ADD CONSTRAINT `trips_ibfk_2` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`);

--
-- Constraints for table `vehicles`
--
ALTER TABLE `vehicles`
  ADD CONSTRAINT `vehicles_ibfk_1` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
