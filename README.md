# Pet Tracking Application

This is a pet tracking application that stores and retrieves data from different trackers for different pets.

## How to run the application
- Install Docker Engine depending upon your type of system. You can find different packages [here](https://docs.docker.com/engine/install/).
- Pull the repo to your local system.
- Run your terminal. Go to path of the repo where you have downloaded the repo.
- Run docker-compose  up --build. This will take a while first time to download all dependencies.
- That is it and go to http://localhost:3000/ to make sure it is up and running.

## Code Organization

### Controllers
It has only one controller called `PetsController`. Which is responsible for receiving the requests from different trackers to store the date, query for data and also to provide information about the number of pets currently outside the power saving zone grouped by pet type and tracker type.

- `index` action --> Responsible for retrieving data from redis. It supports filtering too, You can filter it based on `pet_type` and `tracker_type` params.
- `create` acton --> Responsible for creating data in redis. It supports different params i.e `owner_id`, `pet_type`, `tacker_type`, `in_zone` and `lost_tracker`.
- `show` action --> Responsible for retrieving data from redis based on `owner_id`. It supports filtering owner pet data based on `pet_type` and `tracker_type`.
- `count` action --> Responsible for retrieving count of pets outside the power saving zone. It supports filtering of grouped count data based on `pet_type` and `tracker_type`.

### Services
- Service classes handle different logic to store, retrieve data based on different filters. It is also responsible for validating payload sent by different trackers before storing the data in redis to maintain data consistency. It is also responsible for validating different filter params while retrieving the data.

- `CreatePet` -->  This handles validating the pet info attributes and its type, It is also responsible for storing the pet tracking information. This also handles the logic to update count of pets outside the zone grouped by pet_type and tracker_type.

- `SearchPets` -->  This handles querying/searching of pets according owner_id, pet_type, tracker_type. This uses same redis key `pets_data` list which stores all the pet information to filter/search for the tracking info.
This creates key according to arguments given and finds all the keys in the `pets_data`that match the key. Then we loop the keys to fetch tracking info of all the pets with different trackers.

- `CountPets` --> This handled querying/searching to fetch count of pets outside power saving zone from the `grouped_data` list which is grouped by `pet_type` and `tracker_type`. This takes 2 optional arguments to fetch specific group count.

## Database Design
I've used `Redis` as in-memory database. It is one of the fastest out there and supports different data structure and scalar types.

### Design DS to store the data
I thought of two Data structures to store the tracking data. Both has pros and cons. I gave thought and went with **second option** as system needs to be efficient in querying data specifically when it comes to data receiving from the trackers which sends a huge amounts of data.

### First Option
One with the straight forward option of storing all the data in a single array.For example below

```
[  
  { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: true, lost_tracker: false },
  { pet_type: 'dog', tracker_type: 'small', owner_id: 1, in_zone: true },
  { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: false, lost_tracker: false },
  { pet_type: 'dog', tracker_type: 'small', owner_id: 1, in_zone: true }
]
```

#### Pros
- Easy to store the data. 
- One single list to maintain.

#### Cons
- Not so efficient to retrieve the data. We need to make a linear search every time to query for the data which has runtime complexity of O(N).

### Second Option
To store the pet tacking information using hash mapping. With the unique key based on `owner_id`, `pet_type` and `tracker_type`. Each key has all the pet tracking information belonging to owners pet. For example below

```
{
  "1_cat_small" => [
    { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: true, lost_tracker: false },
    { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: false, lost_tracker: false }
    ]
}
{
  "2_dog_medium" => [
    { pet_type: 'dog', tracker_type: 'medium', owner_id: 2, in_zone: true },
    { pet_type: 'dog', tracker_type: 'medium', owner_id: 2, in_zone: false }
  ]
}
```

#### Pros
- Efficient to retrieve data as we have unique combination of keys with `owner_id`, `pet_type` and `tracker_type`. We can retrieve the data with an average of O(1) complexity.

#### Cons
- Difficult to store and retrieve information. We need to convert data to json for storing the data and parse the json while retrieving data.

### Design DS to store the count of pets outside power saving zone.
- I thought it is easy to store and update the count while storing the data instead of fetching count at runtime of the request.
- This made me to come to decision to store all the data in a `hash` which updates the count according to information provided `in_zone` attribute of different trackers.
- You can refer `update_grouped_data` method of `CreatePet` service for the logic to update the count according to `pet_type` and `tracker_type`.

```
  { 'tracker_type' => 'small', 'pet_type' => 'dog', 'count' => 0 },
  { 'tracker_type' => 'small', 'pet_type' => 'cat', 'count' => 1 },
  { 'tracker_type' => 'medium', 'pet_type' => 'dog', 'count' => 1 },
  { 'tracker_type' => 'big', 'pet_type' => 'dog', 'count' => 1 },
  { 'tracker_type' => 'big', 'pet_type' => 'cat', 'count' => 1 }
```

## Example requests for CURL to store, retrieve the data

### Create/Store the data

```
curl --location 'http://localhost:3000/api/v1/pets' \
--header 'Content-Type: application/json' \
--data '{
    "pet_type": "cat",
    "tracker_type": "medium",
    "owner_id": 100,
    "in_zone": true,
    "lost_tracker": false
}'
```

### Retrieve all the pets data of different owners with different filter options

#### To fetch all the pets data
```
curl http://localhost:3000/api/v1/pets
```

#### To fetch all the pets data filtered by pet_type and tracker_type param

```
curl -G -d "pet_type=#{dog|cat}" -d "tracker_type=#{small|medium|big}" http://localhost:3000/api/v1/pets
```

### Retrieve pets data of a specific owner with different filter options

#### To fetch owners pets data

```
curl http://localhost:3000/api/v1/pets/:owner_id
```

#### To fetch owners pet data filtered by pet_type and tracker_type param

```
 curl -G -d "pet_type=#{dog|cat}" -d "tracker_type=#{small|medium|big}" http://localhost:3000/api/v1/pets/:owner_id
```

### Retrieve count of pets outside power saving zone grouped by pet_type and tracker_type

#### To fetch count of pets outside the zone of all the combination of grouped data by pet_type and tracker_type

```
curl http://localhost:3000/api/v1/pets/count
```

#### To fetch count of pets outside the zone for a specific pet_type and grouped_type param

```
curl -G -d "pet_type=#{dog|cat}" -d "tracker_type=#{small|medium|big}" http://localhost:3000/api/v1/pets/count
```