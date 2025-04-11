#!/bin/bash

# =================================================================
# Voltaris Website Docker Deployment Script
# Features:
# - Configurable port
# - Environment selection (dev, staging, production)
# - Build and deployment options
# - Container management
# - Monitoring and diagnostics
# =================================================================

# ANSI color codes for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default configuration
PORT=3000
ENVIRONMENT="production"
BUILD=true
DETACHED=true
CONTAINER_NAME="voltaris-website"
DOCKER_COMPOSE_FILE="docker-compose.yml"
LOGS_DIR="./docker-logs"

# Show banner
show_banner() {
    echo -e "${BLUE}${BOLD}"
    echo -e "██╗   ██╗ ██████╗ ██╗  ████████╗ █████╗ ██████╗ ██╗███████╗"
    echo -e "██║   ██║██╔═══██╗██║  ╚══██╔══╝██╔══██╗██╔══██╗██║██╔════╝"
    echo -e "██║   ██║██║   ██║██║     ██║   ███████║██████╔╝██║███████╗"
    echo -e "╚██╗ ██╔╝██║   ██║██║     ██║   ██╔══██║██╔══██╗██║╚════██║"
    echo -e " ╚████╔╝ ╚██████╔╝███████╗██║   ██║  ██║██║  ██║██║███████║"
    echo -e "  ╚═══╝   ╚═════╝ ╚══════╝╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝"
    echo -e "${NC}"
    echo -e "${CYAN}${BOLD}Docker Deployment Tool${NC} ${GRAY}v1.0.0${NC}"
    echo -e "\n"
}

# Check if Docker is installed and running
check_docker() {
    echo -e "${YELLOW}${BOLD}Checking Docker...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}${BOLD}Error: Docker is not installed or not in PATH.${NC}"
        echo -e "Please install Docker from https://docs.docker.com/get-docker/"
        exit 1
    else
        echo -e "${GREEN}✓ Docker is installed${NC}"
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}${BOLD}Error: Docker daemon is not running or you don't have permissions.${NC}"
        echo -e "Start Docker Desktop or docker service and try again."
        exit 1
    else
        echo -e "${GREEN}✓ Docker daemon is running${NC}"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Warning: docker-compose not found as standalone command.${NC}"
        echo -e "${GRAY}Will use 'docker compose' instead (Docker Compose V2).${NC}"
        DOCKER_COMPOSE_CMD="docker compose"
    else
        echo -e "${GREEN}✓ docker-compose is installed${NC}"
        DOCKER_COMPOSE_CMD="docker-compose"
    fi
}

# Initialize environment
initialize() {
    echo -e "${YELLOW}${BOLD}Initializing environment...${NC}"
    
    # Create logs directory
    if [ ! -d "$LOGS_DIR" ]; then
        mkdir -p "$LOGS_DIR"
        echo -e "${GREEN}✓ Created logs directory${NC}"
    fi
    
    # Check for required files
    if [ ! -f "Dockerfile" ]; then
        echo -e "${RED}${BOLD}Error: Dockerfile not found.${NC}"
        exit 1
    fi
    
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        echo -e "${RED}${BOLD}Error: $DOCKER_COMPOSE_FILE not found.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All required files found${NC}"
    
    # Check for .env file and create if not exists
    if [ ! -f ".env" ]; then
        echo "PORT=$PORT" > .env
        echo "APP_ENV=$ENVIRONMENT" >> .env
        echo "API_URL=/api" >> .env
        echo "# Add other environment variables here" >> .env
        echo -e "${GREEN}✓ Created default .env file${NC}"
    else
        echo -e "${GREEN}✓ Using existing .env file${NC}"
    fi
}

# Build the Docker image
build_image() {
    echo -e "${YELLOW}${BOLD}Building Docker image...${NC}"
    
    # Use the appropriate docker-compose command
    $DOCKER_COMPOSE_CMD -f $DOCKER_COMPOSE_FILE build --no-cache
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}${BOLD}Error: Docker image build failed.${NC}"
        exit 1
    else
        echo -e "${GREEN}${BOLD}Docker image built successfully!${NC}"
    fi
}

# Deploy the container
deploy_container() {
    echo -e "${YELLOW}${BOLD}Deploying container...${NC}"
    
    # Check if container is already running
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo -e "${YELLOW}Container $CONTAINER_NAME is already running.${NC}"
        read -p "Do you want to stop and redeploy it? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Stopping existing container...${NC}"
            $DOCKER_COMPOSE_CMD -f $DOCKER_COMPOSE_FILE down
        else
            echo -e "${YELLOW}Deployment aborted.${NC}"
            return 1
        fi
    fi
    
    # Set environment variables if needed
    export PORT=$PORT
    export APP_ENV=$ENVIRONMENT
    
    # Deploy with docker-compose
    if [ "$DETACHED" = true ]; then
        $DOCKER_COMPOSE_CMD -f $DOCKER_COMPOSE_FILE up -d
    else
        $DOCKER_COMPOSE_CMD -f $DOCKER_COMPOSE_FILE up
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}${BOLD}Error: Container deployment failed.${NC}"
        exit 1
    else
        echo -e "${GREEN}${BOLD}Container deployed successfully!${NC}"
    fi
    
    # Check if the container is actually running
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo -e "${GREEN}${BOLD}Container $CONTAINER_NAME is running.${NC}"
        
        # Get the container's IP
        CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_NAME)
        
        echo -e "${GREEN}Container IP: $CONTAINER_IP${NC}"
        echo -e "${GREEN}Website available at: http://localhost:$PORT${NC}"
    else
        echo -e "${RED}${BOLD}Warning: Container was started but is not running.${NC}"
        echo -e "${YELLOW}Check logs for more information.${NC}"
    fi
}

# Show container status
show_status() {
    echo -e "${YELLOW}${BOLD}Container status:${NC}"
    
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo -e "${GREEN}${BOLD}Container $CONTAINER_NAME is running.${NC}"
        
        # Get container details
        CONTAINER_ID=$(docker ps -q -f name=$CONTAINER_NAME)
        CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_NAME)
        CONTAINER_CREATED=$(docker inspect -f '{{ .Created }}' $CONTAINER_NAME)
        CONTAINER_STATUS=$(docker inspect -f '{{ .State.Status }}' $CONTAINER_NAME)
        CONTAINER_HEALTH=$(docker inspect -f '{{ .State.Health.Status }}' $CONTAINER_NAME 2>/dev/null || echo "N/A")
        
        echo -e "${CYAN}Details:${NC}"
        echo -e "  ${GRAY}Container ID:${NC} ${GREEN}$CONTAINER_ID${NC}"
        echo -e "  ${GRAY}IP Address:${NC} ${GREEN}$CONTAINER_IP${NC}"
        echo -e "  ${GRAY}Created:${NC} ${GREEN}$CONTAINER_CREATED${NC}"
        echo -e "  ${GRAY}Status:${NC} ${GREEN}$CONTAINER_STATUS${NC}"
        echo -e "  ${GRAY}Health:${NC} ${GREEN}$CONTAINER_HEALTH${NC}"
        echo -e "  ${GRAY}Port Mapping:${NC} ${GREEN}$PORT -> 80${NC}"
        echo -e "  ${GRAY}Website URL:${NC} ${GREEN}http://localhost:$PORT${NC}"
    else
        echo -e "${YELLOW}Container $CONTAINER_NAME is not running.${NC}"
    fi
}

# Show container logs
show_logs() {
    echo -e "${YELLOW}${BOLD}Container logs:${NC}"
    
    if docker ps -a -q -f name=$CONTAINER_NAME | grep -q .; then
        docker logs $CONTAINER_NAME
    else
        echo -e "${YELLOW}Container $CONTAINER_NAME does not exist.${NC}"
    fi
}

# Stop container
stop_container() {
    echo -e "${YELLOW}${BOLD}Stopping container...${NC}"
    
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        $DOCKER_COMPOSE_CMD -f $DOCKER_COMPOSE_FILE down
        echo -e "${GREEN}${BOLD}Container stopped.${NC}"
    else
        echo -e "${YELLOW}Container $CONTAINER_NAME is not running.${NC}"
    fi
}

# Restart container
restart_container() {
    echo -e "${YELLOW}${BOLD}Restarting container...${NC}"
    
    if docker ps -a -q -f name=$CONTAINER_NAME | grep -q .; then
        $DOCKER_COMPOSE_CMD -f $DOCKER_COMPOSE_FILE restart
        echo -e "${GREEN}${BOLD}Container restarted.${NC}"
    else
        echo -e "${YELLOW}Container $CONTAINER_NAME does not exist. Use deploy instead.${NC}"
    fi
}

# Show help
show_help() {
    echo -e "${BLUE}${BOLD}Voltaris Website Docker Deployment Tool - Help${NC}"
    echo -e "${GRAY}Deploy your Voltaris website using Docker and Nginx${NC}\n"
    
    echo -e "${CYAN}USAGE:${NC}"
    echo -e "  ${GRAY}./docker-deploy.sh <command> [options]${NC}\n"
    
    echo -e "${CYAN}COMMANDS:${NC}"
    echo -e "  ${GREEN}deploy${NC}    ${GRAY}Build and deploy the container${NC}"
    echo -e "  ${GREEN}status${NC}    ${GRAY}Show container status${NC}"
    echo -e "  ${GREEN}logs${NC}      ${GRAY}Show container logs${NC}"
    echo -e "  ${GREEN}stop${NC}      ${GRAY}Stop the container${NC}"
    echo -e "  ${GREEN}restart${NC}   ${GRAY}Restart the container${NC}"
    echo -e "  ${GREEN}help${NC}      ${GRAY}Show this help message${NC}\n"
    
    echo -e "${CYAN}OPTIONS:${NC}"
    echo -e "  ${GREEN}--port, -p <port>${NC}         ${GRAY}Specify port (default: 3000)${NC}"
    echo -e "  ${GREEN}--env, -e <environment>${NC}   ${GRAY}Set environment: dev, staging, prod (default: production)${NC}"
    echo -e "  ${GREEN}--no-build, -nb${NC}           ${GRAY}Skip building the image${NC}"
    echo -e "  ${GREEN}--foreground, -fg${NC}         ${GRAY}Run in foreground (not detached)${NC}\n"
    
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo -e "  ${GRAY}./docker-deploy.sh deploy${NC}"
    echo -e "  ${GRAY}./docker-deploy.sh deploy -p 8080 -e dev${NC}"
    echo -e "  ${GRAY}./docker-deploy.sh deploy -fg${NC}"
    echo -e "  ${GRAY}./docker-deploy.sh status${NC}"
    echo -e "  ${GRAY}./docker-deploy.sh logs${NC}"
    echo -e "  ${GRAY}./docker-deploy.sh stop${NC}\n"
    
    return 0
}

# Parse command line arguments
parse_arguments() {
    COMMAND=${1:-help}
    shift || true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --port|-p)
                PORT="$2"
                shift 2
                ;;
            --env|-e)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --no-build|-nb)
                BUILD=false
                shift
                ;;
            --foreground|-fg)
                DETACHED=false
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    show_banner
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Check Docker installation
    check_docker
    
    # Process command
    case $COMMAND in
        deploy)
            initialize
            if [ "$BUILD" = true ]; then
                build_image
            fi
            deploy_container
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        stop)
            stop_container
            ;;
        restart)
            restart_container
            ;;
        help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown command: $COMMAND${NC}"
            show_help
            exit 1
            ;;
    esac
    
    exit 0
}

# Call main with all arguments
main "$@"
