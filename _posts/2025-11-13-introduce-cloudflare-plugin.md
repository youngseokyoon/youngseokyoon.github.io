---
layout: post
title:
date: 2025-11-13
tags:
  - imgur
  - obsidian
categories:
  - obsidian
  - cloudflare
imageNameKey: cloudflare-plugin
---
imgur 에서 신규 유저 가입 중단 및 신규 app 등록이 중단 된 것으로 보임.
따라서 imgur 을 대체할 수 있는 방법 찾음.

원하는 기능:
스크린샷 한 이미지를 문서에 붙여넣었을 때 자동으로 cloud 에 업로드 및 이미지의 링크가 문서에 삽입
이 기능이 있어야 [imgur](https://github.com/gavvvr/obsidian-imgur-plugin) 를 대체할 수 있다고 판단.
아쉽게도 이 기능이 있는 플러그인은 찾을 수 없었음.

따라서 새로 만들기로 함.

다행이도 참고할 수 있는 플러그인을 찾아서 이것을 베이스로 신규 기능을 추가함.
[참고한 obsidian 플러그인](https://github.com/addozhang/obsidian-image-upload-toolkit)

먼저 이미지를 업로드하기 위해 Cloud Storage Services 를 비교를 해봤음.
[cloud storage services 비교](https://github.com/addozhang/obsidian-image-upload-toolkit#supported-storage-services-8-providers) 참고해서 결정함.

| Service          | Free Tier     | Rating | Best For             |
|------------------|---------------|--------|----------------------|
| Imgur            | Limited       | ⭐⭐⭐    | Personal blogs       |
| GitHub           | Unlimited     | ⭐⭐⭐⭐   | Open source projects |
| Cloudflare R2    | Pay-as-you-go | ⭐⭐⭐⭐⭐  | Professional use     |
| AWS S3           | Pay-as-you-go | ⭐⭐⭐⭐   | Enterprise           |
| Aliyun OSS       | Pay-as-you-go | ⭐⭐⭐⭐   | Chinese users        |
| TencentCloud COS | Pay-as-you-go | ⭐⭐⭐⭐   | Chinese users        |
| Qiniu Kodo       | Pay-as-you-go | ⭐⭐⭐⭐   | Chinese users        |
| ImageKit         | Limited       | ⭐⭐⭐⭐   | CDN optimization     |

비용 걱정으로 인해 무료로 가입이 가능하면서 사용량이 충분하면서,
평점이 높고 global 하게 사용할 수 있을 것 같은 Cloudflare R2 로 결정.

해당 plugin 을 사용하기 위해선 먼저 Cloudflare 가입을 해야 함.
[Cloudflare free 요금제 정보](https://www.cloudflare.com/ru-ru/plans/free/)


가입을 할 때 신용/체크카드 등록이 필요.

- Free tier 사용량 참고
![cloudflare-plugin/uvildl5f8new](https://pub-dcf0b2529ee44fbfb67ee348978333d1.r2.dev/2025-12-02-cloudflare-plugin/uvildl5f8new.png)


# Cloudflare R2 관련 설정
## Bucket 생성하기
![cloudflare-plugin/3wjd7dvi4nbq](https://pub-dcf0b2529ee44fbfb67ee348978333d1.r2.dev/2025-11-25-cloudflare-plugin/3wjd7dvi4nbq.png)

## R2 API Token 생성하기

1. https://dash.cloudflare.com 접속 
2. 왼쪽 메뉴 R2 Object Storage -> 개요 클릭

![ovjgukdz5lp.png](https://pub-dcf0b2529ee44fbfb67ee348978333d1.r2.dev/imagetest-0vjgukdz5lp0.png)

3. Account Details -> API Tokens Manage 클릭

![mkp53v9jr75h.png](https://pub-dcf0b2529ee44fbfb67ee348978333d1.r2.dev/mkp53v9jr75h.png)

4. User API 토큰 생성

![[6p504jjnq3ff.png](https://pub-dcf0b2529ee44fbfb67ee348978333d1.r2.dev/6p504jjnq3ff.png)

5. API 토큰 생성
- obsidian-images 라는 버킷에만 접근 가능한 1년 access Token 생성함
- 값 설정 후 Create User API Token 클릭

![btrb4duevllo.png](https://pub-dcf0b2529ee44fbfb67ee348978333d1.r2.dev/btrb4duevllo.png)

5. 생성된 User API Token 정보 기록하기
Token value, Access Key ID, Secret Access Key, endpoints 정보를 기록해준다.
해당 정보는 외부에 공개 되지 않도록 주의.

[![jxkfnp5ifz0e.png](https://pub-dcf0b2529ee44fbfb67ee348978333d1.r2.dev/jxkfnp5ifz0e.png)

## R2 Bucket 설정
위의 설정을 하고 테스트를 하면 upload 실패가 발생.
```console
Failed to upload imagetest/a6ik3v593zcj.png: NetworkingError: Network Failure
    at XMLHttpRequest.eval (plugin:obsidian-cloudflare-plugin:17051:39)
```

생성한 Bucket 의 CORS 정책위반으로 upload 가 실패하고 있음.

생성한 R2 Object Storage -> Settings 으로 이동
CORS Policy 를 클릭하면, 아래 처럼 localhost:3000 을 통한 GET 만 허용을 해놨음.
```
[
  {
    "AllowedOrigins": [
      "http://localhost:3000"
    ],
    "AllowedMethods": [
      "GET"
    ]
  }
]
```


아래 처럼 수정하면 upload 성공.
```
[
  {
    "AllowedOrigins": [
      "app://obsidian.md",
      "http://localhost:3000"
    ],
    "AllowedMethods": [
      "GET",
      "PUT",
      "POST",
      "DELETE",
      "HEAD"
    ],
    "AllowedHeaders": [
      "*"
    ],
    "ExposeHeaders": [
      "ETag",
      "Content-Length",
      "Content-Type"
    ],
    "MaxAgeSeconds": 3600
  }
]
```

설정 확인

![cloudflare-plugin/96n1j6ngatjl](https://pub-dcf0b2529ee44fbfb67ee348978333d1.r2.dev/2025-11-25-cloudflare-plugin/96n1j6ngatjl.png)


자세한 플러그인 설정을 아래 Github page 참고
[obsidian-cloudflare-plugin](https://youngseokyoon.github.io/obsidian-cloudflare-plugin/README.ko.html)


obsidian community plugin 에 추가하기 위한 PR 진행 중.
[obsidian-releases-8785](https://github.com/obsidianmd/obsidian-releases/pull/8785)
