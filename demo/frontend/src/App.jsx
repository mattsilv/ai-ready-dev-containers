import { useState, useEffect, useRef } from "react";
import "./App.css";
import axios from "axios";

// Configure Axios with the base URL from the environment variable
const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8001";
axios.defaults.baseURL = API_URL;

function App() {
  const [items, setItems] = useState([]);

  // Format current date and time in a friendly format
  const now = new Date();
  const options = {
    month: "long",
    day: "numeric",
    hour: "numeric",
    minute: "numeric",
    hour12: true,
  };
  const formattedDateTime = now.toLocaleDateString("en-US", options);

  const [newItem, setNewItem] = useState({
    name: "vibe coder",
    description: `this is my first dev container on ${formattedDateTime}`,
  });

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [apiHealth, setApiHealth] = useState(null);
  const [highlight, setHighlight] = useState(false);
  const itemsContainerRef = useRef(null);

  // Check API health
  useEffect(() => {
    const checkHealth = async () => {
      try {
        const response = await axios.get("/health");
        setApiHealth(response.data.status);
      } catch (err) {
        setApiHealth("down");
        console.error("Health check failed:", err);
      }
    };

    checkHealth();
  }, []);

  // Fetch items from API
  useEffect(() => {
    const fetchItems = async () => {
      try {
        setLoading(true);
        const response = await axios.get("/items");
        // Sort items in descending order by ID (newest first)
        const sortedItems = [...response.data].sort((a, b) => b.id - a.id);
        setItems(sortedItems);
        setError(null);
      } catch (err) {
        setError("Error fetching items. Is the backend running?");
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    fetchItems();
  }, []);

  // Handle form input changes
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNewItem({ ...newItem, [name]: value });
  };

  // Handle form submission to create new item
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!newItem.name) return;

    try {
      const response = await axios.post("/items", newItem);
      // Add new item to the beginning of the array (descending order)
      setItems([response.data, ...items]);
      setNewItem({ name: "", description: "" });
      setError(null);

      // Trigger highlight effect
      setHighlight(true);
      setTimeout(() => setHighlight(false), 2000);

      // Scroll to the items container
      if (itemsContainerRef.current) {
        itemsContainerRef.current.scrollIntoView({ behavior: "smooth" });
      }
    } catch (err) {
      setError("Error creating item");
      console.error(err);
    }
  };

  return (
    <div className="container">
      <header className="app-header">
        <h1>👋 Hello World!</h1>
        <h2>DevContainer Demo App</h2>
        <div className="status-badge">
          <span>API Status:</span>
          <span
            className={`status ${
              apiHealth === "healthy" ? "online" : "offline"
            }`}
          >
            {apiHealth === "healthy" ? "Online" : "Offline"}
          </span>
        </div>
      </header>

      <p className="description">
        This simple app demonstrates a complete fullstack application running in
        a development container. It features a <strong>React</strong> frontend,{" "}
        <strong>FastAPI</strong> backend, and <strong>SQLite</strong> database.
      </p>

      <div className="demo-info">
        <h3>Stack Details:</h3>
        <ul>
          <li>
            ⚛️ <strong>Frontend:</strong> React + Vite
          </li>
          <li>
            🐍 <strong>Backend:</strong> Python + FastAPI
          </li>
          <li>
            🗄️ <strong>Database:</strong> SQLite
          </li>
          <li>
            🐳 <strong>Environment:</strong> Docker + Dev Containers
          </li>
        </ul>
      </div>

      {error && <div className="error">{error}</div>}

      <div className="card">
        <h2>Add New Item</h2>
        <div className="try-it-prompt">
          👉 Try it now! Add an item to see it appear in the database.
        </div>
        <form onSubmit={handleSubmit} className="horizontal-form">
          <div className="form-group">
            <label htmlFor="name">Name:</label>
            <input
              type="text"
              id="name"
              name="name"
              value={newItem.name}
              onChange={handleInputChange}
              required
              placeholder="Enter item name"
            />
          </div>
          <div className="form-group">
            <label htmlFor="description">Description:</label>
            <input
              type="text"
              id="description"
              name="description"
              value={newItem.description}
              onChange={handleInputChange}
              placeholder="Enter item description"
            />
          </div>
          <button type="submit">Add Item</button>
        </form>
      </div>

      <div
        ref={itemsContainerRef}
        className={`items-container ${highlight ? "highlight-animation" : ""}`}
      >
        <h2>Database Items</h2>
        {loading ? (
          <p>Loading items from database...</p>
        ) : items.length > 0 ? (
          <ul className="items-list">
            {items.map((item) => (
              <li key={item.id} className="item">
                <h3>{item.name}</h3>
                <p>{item.description || "No description provided"}</p>
                <div className="item-meta">
                  <span>ID: {item.id}</span>
                  <span>
                    Created: {new Date(item.created_at).toLocaleString()}
                  </span>
                </div>
              </li>
            ))}
          </ul>
        ) : (
          <p>No items found in the database. Add some above!</p>
        )}
      </div>
    </div>
  );
}

export default App;
