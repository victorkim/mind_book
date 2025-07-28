#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ErrorCode,
  ListToolsRequestSchema,
  McpError,
} from '@modelcontextprotocol/sdk/types.js';
import axios from 'axios';

// Configuration
const RAILS_API_BASE_URL = 'http://localhost:3000/api/v1/mcp';

// Create axios instance with default config
const api = axios.create({
  baseURL: RAILS_API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Initialize MCP server
const server = new Server(
  {
    name: 'rails-project-manager',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Error handler wrapper
async function handleApiCall(apiCall) {
  try {
    const response = await apiCall();
    return response.data;
  } catch (error) {
    console.error('API Error:', error.message);
    if (error.response) {
      throw new McpError(
        ErrorCode.InternalError,
        `Rails API Error: ${error.response.data.message || error.message}`
      );
    }
    throw new McpError(
      ErrorCode.InternalError,
      `Network Error: ${error.message}`
    );
  }
}

// Handle tool listing
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'list_channels',
        description: 'List all available channels (meeting types)',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
      {
        name: 'list_projects',
        description: 'List all projects',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
      {
        name: 'find_channel',
        description: 'Find a channel by name',
        inputSchema: {
          type: 'object',
          properties: {
            name: {
              type: 'string',
              description: 'The name of the channel to find',
            },
          },
          required: ['name'],
        },
      },
      {
        name: 'add_comment_to_channel',
        description: 'Add a comment to a channel for a specific project',
        inputSchema: {
          type: 'object',
          properties: {
            channel_name: {
              type: 'string',
              description: 'The name of the channel',
            },
            project_name: {
              type: 'string',
              description: 'The name of the project this comment relates to',
            },
            body: {
              type: 'string',
              description: 'The comment text/summary',
            },
            date: {
              type: 'string',
              description: 'Date of the comment (YYYY-MM-DD format). Defaults to today if not provided.',
            },
          },
          required: ['channel_name', 'project_name', 'body'],
        },
      },
      {
        name: 'list_recent_comments',
        description: 'List recent comments',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
      {
        name: 'create_channel',
        description: 'Create a new channel/meeting type',
        inputSchema: {
          type: 'object',
          properties: {
            name: {
              type: 'string',
              description: 'The name of the channel (e.g., "DEMO: Weekly Engineering Sync")',
            },
          },
          required: ['name'],
        },
      },
      {
        name: 'create_project',
        description: 'Create a new project',
        inputSchema: {
          type: 'object',
          properties: {
            name: {
              type: 'string',
              description: 'The name of the project',
            },
            description: {
              type: 'string',
              description: 'Project description',
            },
            department: {
              type: 'string',
              description: 'Department (e.g., Sales, Marketing, Engineering, RevOps)',
            },
            start_date: {
              type: 'string',
              description: 'Start date (YYYY-MM-DD format)',
            },
            end_date: {
              type: 'string',
              description: 'End date (YYYY-MM-DD format)',
            },
          },
          required: ['name', 'department', 'start_date', 'end_date'],
        },
      },
      {
        name: 'delete_project',
        description: 'Delete a project by ID',
        inputSchema: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'The ID of the project to delete',
            },
          },
          required: ['id'],
        },
      },
      {
        name: 'delete_channel',
        description: 'Delete a channel by ID',
        inputSchema: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'The ID of the channel to delete',
            },
          },
          required: ['id'],
        },
      },
      {
        name: 'bulk_delete_demo',
        description: 'Delete all demo projects, channels, and comments',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
    ],
  };
});

// Handle tool execution
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case 'list_channels': {
      const result = await handleApiCall(() => api.get('/channels'));
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(result.data, null, 2),
          },
        ],
      };
    }

    case 'list_projects': {
      const result = await handleApiCall(() => api.get('/projects'));
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(result.data, null, 2),
          },
        ],
      };
    }

    case 'find_channel': {
      const channelsResult = await handleApiCall(() => api.get('/channels'));
      const channels = channelsResult.data;
      
      // Find channel by name (case-insensitive)
      const channel = channels.find(
        (ch) => ch.name.toLowerCase() === args.name.toLowerCase()
      );
      
      if (!channel) {
        throw new McpError(
          ErrorCode.InvalidRequest,
          `Channel '${args.name}' not found`
        );
      }
      
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(channel, null, 2),
          },
        ],
      };
    }

    case 'add_comment_to_channel': {
      // First, find the channel
      const channelsResult = await handleApiCall(() => api.get('/channels'));
      const channels = channelsResult.data;
      
      const channel = channels.find(
        (ch) => ch.name.toLowerCase() === args.channel_name.toLowerCase()
      );
      
      if (!channel) {
        throw new McpError(
          ErrorCode.InvalidRequest,
          `Channel '${args.channel_name}' not found`
        );
      }
      
      // Create the comment
      const commentData = {
        project_name: args.project_name,
        body: args.body,
        date: args.date || new Date().toISOString().split('T')[0],
      };
      
      const result = await handleApiCall(() =>
        api.post(`/channels/${channel.id}/comments`, commentData)
      );
      
      return {
        content: [
          {
            type: 'text',
            text: `Successfully added comment to channel '${args.channel_name}' for project '${args.project_name}':\n${JSON.stringify(result.data, null, 2)}`,
          },
        ],
      };
    }

    case 'list_recent_comments': {
      const result = await handleApiCall(() => api.get('/comments'));
      const comments = result.data.slice(0, 10); // Get last 10 comments
      
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(comments, null, 2),
          },
        ],
      };
    }

    case 'create_channel': {
      const channelData = {
        name: args.name,
      };
      
      const result = await handleApiCall(() =>
        api.post('/channels', channelData)
      );
      
      return {
        content: [
          {
            type: 'text',
            text: `Successfully created channel '${args.name}':\n${JSON.stringify(result.data, null, 2)}`,
          },
        ],
      };
    }

    case 'create_project': {
      const projectData = {
        name: args.name,
        description: args.description || '',
        department: args.department,
        start_date: args.start_date,
        end_date: args.end_date,
      };
      
      const result = await handleApiCall(() =>
        api.post('/projects', projectData)
      );
      
      return {
        content: [
          {
            type: 'text',
            text: `Successfully created project '${args.name}':\n${JSON.stringify(result.data, null, 2)}`,
          },
        ],
      };
    }

    case 'delete_project': {
      const result = await handleApiCall(() =>
        api.delete(`/projects/${args.id}`)
      );
      
      return {
        content: [
          {
            type: 'text',
            text: `Successfully deleted project with ID ${args.id}:\n${JSON.stringify(result, null, 2)}`,
          },
        ],
      };
    }

    case 'delete_channel': {
      const result = await handleApiCall(() =>
        api.delete(`/channels/${args.id}`)
      );
      
      return {
        content: [
          {
            type: 'text',
            text: `Successfully deleted channel with ID ${args.id}:\n${JSON.stringify(result, null, 2)}`,
          },
        ],
      };
    }

  case 'bulk_delete_demo': {
    const results = {};
    
    // Try to delete demo projects
    try {
      const projectsResult = await handleApiCall(() =>
        api.delete('/projects/bulk_delete_demo')
      );
      results.projects = { success: true, data: projectsResult };
    } catch (error) {
      results.projects = { success: false, error: error.message };
    }
    
    // Try to delete demo channels
    try {
      const channelsResult = await handleApiCall(() =>
        api.delete('/channels/bulk_delete_demo')
      );
      results.channels = { success: true, data: channelsResult };
    } catch (error) {
      results.channels = { success: false, error: error.message };
    }
    
    // Try to delete demo comments
    try {
      const commentsResult = await handleApiCall(() =>
        api.delete('/comments/bulk_delete_demo')
      );
      results.comments = { success: true, data: commentsResult };
    } catch (error) {
      results.comments = { success: false, error: error.message };
    }
    
    return {
      content: [
        {
          type: 'text',
          text: `Bulk delete demo results:\n${JSON.stringify(results, null, 2)}`,
        },
      ],
    };
  }

    default:
      throw new McpError(
        ErrorCode.MethodNotFound,
        `Unknown tool: ${name}`
      );
  }
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Rails MCP server running on stdio');
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});