# Ouro Carrier Pigeon

A sophisticated carrier pigeon messaging system for RedM servers, allowing players to send messages across the frontier using trained carrier pigeons.

## Features

- **Carrier Pigeon System**: Send messages to other players using carrier pigeons
- **Training System**: Train your pigeon to know specific locations
- **Realistic Delivery**: Pigeons must be trained to deliver to specific areas
- **Distance-Based Timing**: Delivery time scales with distance
- **Material Requirements**: Requires pen and paper to send messages
- **Unique Pigeon IDs**: Each pigeon has a unique identifier
- **Message Inbox**: View and manage received messages
- **Training Zones**: Visual representation of trained areas on the map
- **Animations**: Realistic pigeon takeoff and landing animations

## Requirements

- RedM Server
- VORP Core
- VORP Inventory
- MySQL-Async

## Installation

1. **Download the resource** and place it in your `resources` folder
2. **Import the SQL file**:
   ```sql
   -- Run the contents of sql/pigeons.sql in your database
   ```
3. **Add to server.cfg**:
   ```
   ensure Ouro_CarrierPigeon
   ```
4. **Restart your server**

## Configuration

Edit `config.lua` to customize the system:

```lua
Config = {}

-- Chance the pigeon fails to deliver (0.0 = 0%, 1.0 = 100%)
Config.FailureChance = 0.0
```

## Usage

### Getting Started
1. **Obtain a Carrier Pigeon** item
2. **Use the item** to open the pigeon interface
3. **First use** will register your pigeon with a unique ID

### Sending Messages
1. **Open the pigeon interface** using the carrier pigeon item
2. **Go to the Send tab**
3. **Enter the target pigeon ID** (e.g., P123456)
4. **Write your message**
5. **Click "Dispatch"** to send

**Requirements for sending:**
- 1x Pen
- 1x Blank Paper
- Target must be online
- Your pigeon must be trained for the target's area

### Training Your Pigeon
1. **Go to the Train tab**
2. **Enter a location name** (e.g., "Valentine", "Saint Denis")
3. **Click "Begin Training"**
4. **Stay in the area** for 90 seconds
5. **Training complete!** Your pigeon now knows this location

### Receiving Messages
- **Check your inbox** in the Inbox tab
- **Messages appear automatically** when pigeons arrive
- **Delete old messages** to keep your inbox clean

### Training Zones
- **View all trained zones** in the Train tab
- **Show zones on map** to see where your pigeon can deliver
- **Zone blips** appear as teal areas for 20 seconds

## Technical Details

### Database Tables
- `carrier_pigeons`: Stores pigeon ownership
- `carrier_pigeon_messages`: Stores sent/received messages
- `carrier_pigeon_training`: Stores trained locations

### Delivery Mechanics
- **Distance calculation** between sender and recipient
- **Delivery time** = min(300s, max(10s, distance × 0.15s))
- **Area validation** - pigeon must be trained for recipient's location
- **Online check** - recipient must be online to receive

### Item Requirements
- `carrier_pigeon`: Main item for using the system
- `paper`: Consumed when sending messages
- `pen`: Required to write messages

## Commands

The system uses events and NUI callbacks. No additional commands are required.

## Troubleshooting

### Common Issues
1. **"Pigeon not registered"**: Use the carrier pigeon item once to register
2. **"Need pen and paper"**: Ensure you have both items in your inventory
3. **"Pigeon doesn't know that area"**: Train your pigeon for the target location
4. **"Recipient not found"**: Target player must be online

### Debug Information
- Check server console for debug messages
- Verify database tables are created correctly
- Ensure VORP Core is properly loaded

## API Events

### Server Events
- `carrierpigeon:send` - Send a message
- `carrierpigeon:requestInbox` - Request inbox messages
- `carrierpigeon:deleteMessage` - Delete a message
- `carrierpigeon:trainPigeon` - Train pigeon for a location

### Client Events
- `carrierpigeon:openUI` - Open the pigeon interface
- `carrierpigeon:closeUI` - Close the pigeon interface
- `carrierpigeon:receiveInbox` - Receive inbox data
- `carrierpigeon:sendAnimation` - Play send animation
- `carrierpigeon:receiveAnimation` - Play receive animation

## Support

For support, issues, or feature requests, please contact the development team.

## License

This resource is developed by OuroDev for the RedM community.

---

**Happy messaging on the frontier!**
