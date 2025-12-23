"""
Basic smoke tests for Weather App Functions.
These tests verify the basic structure and imports work correctly.
"""

import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))


def test_imports():
    """Test that all required modules can be imported."""
    try:
        import weather
        import save
        from shared import weather_lib
        assert True, "All imports successful"
    except ImportError as e:
        assert False, f"Import failed: {e}"


def test_weather_module_exists():
    """Test that weather module has the expected structure."""
    import weather
    # Check if main function exists (Azure Functions entry point)
    assert hasattr(weather, 'main'), "Weather module should have a 'main' function"


def test_save_module_exists():
    """Test that save module has the expected structure."""
    import save
    # Check if main function exists (Azure Functions entry point)
    assert hasattr(save, 'main'), "Save module should have a 'main' function"


def test_shared_library_exists():
    """Test that shared weather library exists."""
    try:
        from shared import weather_lib
        # Just verify it imports without errors
        assert weather_lib is not None
    except ImportError:
        assert False, "weather_lib should be importable from shared module"


# Note: Full integration tests would require mocking Azure Functions context,
# database connections, and external API calls. These basic tests just verify
# the code structure is valid.
