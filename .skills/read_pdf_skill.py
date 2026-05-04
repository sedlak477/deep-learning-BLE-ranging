import subprocess
import sys
from pathlib import Path

def read_pdf(pdf_path: str) -> str:
    """
    Extract text from a PDF file.

    Args:
        pdf_path: The absolute or relative path to the PDF file.
        
    Returns:
        The extracted text content of the PDF.
    """
    path = Path(pdf_path)
    if not path.exists():
        return f"Error: PDF file not found at {pdf_path}"
        
    try:
        # Run pdftotext - laid out out as text
        result = subprocess.run(
            ['pdftotext', '-layout', str(path), '-'], 
            capture_output=True, 
            text=True, 
            check=True
        )
        return result.stdout
    except FileNotFoundError:
        return "Error: pdftotext tool is not installed. Please install poppler-utils."
    except subprocess.CalledProcessError as e:
        return f"Error processing PDF: {e.stderr}"
