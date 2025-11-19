---
marp: true
size: 4:3
paginate: true
---

- Feature # 1  Users can see a list of series (Deadline: 09/26)
  - Requirement # 1 
      - Display list of recent series in a Home Page so users will be able to select a series
  - Plan:  Call the MangaDex API to get the most recent list of series
---
- Feature # 2  Users are able to select a manga/manwha/manhua series and select a chapter to read(Deadline: 10/03)  
  - Requirement # 1 
      - Show details of a series
  
  - Requirement # 2
      - List of chapters when you press a series and able to select to read
  - Plan:  Call the MangaDex API to get the list of chapters of the series
---
- Feature # 3  Users are able to search for manga (Deadline: 10/17 )
  - Requirement # 1 
      - Search button that users can use to enter series then shows list of series
  - Plan:  Call the MangaDex API show the listof search results in search page
---
- Feature # 4  Users can add new manga series to their library(locally in their device) (Deadline: 10/24)
  - Requirement # 1 
      - Add a "Add in Library" Button when you are in the detail page(saves locally in their device)
  - Plan:  Get the manga_id, image_url, description, and number of chapters. Store this in SQLite
---