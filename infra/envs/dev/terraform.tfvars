# dev 환경 값. 스케일 실습 때 이 파일을 바꾸고 PR 을 올린다.
web_instance_type    = "t3.micro"
web_min_size         = 1
web_max_size         = 4
web_desired_capacity = 2

db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
