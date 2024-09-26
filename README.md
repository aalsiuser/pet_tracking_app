# Pet Tracking Application

This is a pet tracking application that stores and retrieves data from different trackers for different pets.

## How to run the application
- Install Docker Engine depending on your system. You can find installation packages here.
- Clone the repository to your local system.
- Open a terminal and navigate to the repository's directory.
- Run the following command: docker-compose up --build. The initial run may take some time as dependencies are downloaded.
- Once the setup is complete, visit http://localhost:3000/ to verify that the application is running.
- To run unit and controller tests, use the command rails test. This will execute all the test cases.

## Example requests for CURL to store, retrieve the data

### Create/Store the data

```
curl --location 'http://localhost:3000/api/v1/pets' \
--header 'Content-Type: application/json' \
--data '{
    "pet_type": "#{cat|dog}",
    "tracker_type": "#{small|medium|big}",
    "owner_id": Int,
    "in_zone": Boolean,
    "lost_tracker": Boolean
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


## Code Organization

### Controllers
The application uses a single controller, PetsController, which handles incoming requests from different trackers to store data, query data, and provide information on the number of pets currently outside the power-saving zone, grouped by pet_type and tracker_type.

- `index` action --> Responsible for retrieving data from redis. It supports filtering too, You can filter it based on `pet_type` and `tracker_type` params.
- `create` acton --> Responsible for creating data in redis. It supports different params i.e `owner_id`, `pet_type`, `tacker_type`, `in_zone` and `lost_tracker`.
- `show` action --> Responsible for retrieving data from redis based on `owner_id`. It supports filtering owner pet data based on `pet_type` and `tracker_type`.
- `count` action --> Responsible for retrieving count of pets outside the power saving zone. It supports filtering of grouped count data based on `pet_type` and `tracker_type`.

### Services
Service classes manage the logic for storing and retrieving data based on different filters. They are also responsible for validating payloads from different trackers before storing data in Redis to maintain data consistency, as well as validating filter parameters during data retrieval.

- `CreatePet`: This service validates pet information attributes and their types, and manages the storage of pet tracking information. It also handles updating the count of pets outside the zone, grouped by `pet_type` and `tracker_type`.

- `SearchPets`: This service handles querying and searching for pets based on `owner_id`, `pet_type`, and `tracker_type`. It uses the same Redis key, pets_data, which stores all the pet information, to filter and search for tracking info. Keys are constructed according to the provided arguments, and matching keys are used to fetch the tracking information for all pets with different trackers.

- `CountPets`: This service manages querying and retrieving the count of pets outside the power-saving zone from the grouped_data list, grouped by `pet_type` and `tracker_type`. It accepts two optional arguments to fetch specific group counts.

## Database Design
The application uses Redis as its in-memory database. Redis is one of the fastest databases available and supports a variety of data structures and scalar types.

### Data Structure for Storing Pet Tracking Information
Two options were considered for storing tracking data. After evaluating the pros and cons, I chose the second option to ensure efficient data querying, especially since the system receives large amounts of data from trackers.


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


