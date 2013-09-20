#define DACMN_GLOBAL
#include "da.h"

/* Local functions */
static void process_elements ( xmlNode *a_node );

void da_readxml ( char *filename, int *iret )
/************************************************************************
 * da_readxml								*
 *									*
 * This function reads the XML configuration file. Each element of the	*
 * file is processed and stored in a structure.				*
 *									*
 * da_readxml ( filename, iret )					*
 *									*
 * Input parameters:							*
 *	filename	char*		XML file name			*
 *									*
 * Output parameters:							*
 *	iret		int*		Return Code			*
 **									*
 * Log:									*
 * S. Jacobs/NCEP	 6/13	Created					*
 ************************************************************************/
{
    xmlDoc	*doc = NULL;
    xmlNode	*root_element = NULL;
/*---------------------------------------------------------------------*/
    *iret = 0;

    /* Check the version of the library in use. */
    LIBXML_TEST_VERSION

    /* Read the XML file. */
    doc = xmlReadFile (filename, NULL, 0 );
    if ( doc == NULL ) {
	*iret = -6;
	return;
    }

    /* Get the root element node and start the processing */
    root_element = xmlDocGetRootElement(doc); 
    process_elements(root_element);

    /* Clean up the XML reader when finished */
    xmlFreeDoc ( doc );

    /* Cleanup function for the XML library. */
    xmlCleanupParser ();

    return;
}

/*=====================================================================*/

static void process_elements ( xmlNode *a_node )
/************************************************************************
 * process_elements							*
 * 									*
 * This function will process information about the current node.	*
 * 									*
 * process_elements ( a_node )						*
 *									*
 * Input parameters:							*
 *	a_node		xmlNode*	Next node to process		*
 **									*
 * Log:									*
 * S. Jacobs/NCEP	 6/13	Created					*
 ***********************************************************************/
{
    xmlNode *cur_node = NULL;
    xmlAttr *attr = NULL;

/*---------------------------------------------------------------------*/

    /* Process all nodes and their children */
    for (cur_node = a_node; cur_node; cur_node = cur_node->next) {

	/* Process the node, if it is an XML ELEMENT */
	if (cur_node->type == XML_ELEMENT_NODE) {

	    /* Save the file label and version number */
	    if ( strcmp((char *)cur_node->name,"filelabel") == 0 ) {
		for (attr = cur_node->properties; attr; attr = attr->next) {
		    if ( strcmp((char *)attr->name,"text") == 0 ) {
			common.label = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.label, (char *)attr->children->content );
		    }
		    if ( strcmp((char *)attr->name,"version") == 0 ) {
			common.version = atoi ((char *)attr->children->content ); 
		    }
		}
	    }

	    /* Save the file type and source */
	    if ( strcmp((char *)cur_node->name,"filetype") == 0 ) {
		for (attr = cur_node->properties; attr; attr = attr->next) {
		    if ( strcmp((char *)attr->name,"type") == 0 ) {
			FIND_KEY ( common.type, ((char *)attr->children->content), ftype, Hash_t )
		    }
		    if ( strcmp((char *)attr->name,"source") == 0 || strcmp((char *)attr->name,"rawtext") == 0) {
			int i;
			FIND_KEY ( i, ((char *)attr->children->content), source, Hash_t )
			common.source += i;
		    }
		}
	    }

	    /* Save the AWIPS database server name */
	    if ( strcmp((char *)cur_node->name,"dbserver") == 0 ) {
		for (attr = cur_node->properties; attr; attr = attr->next) {
		    if ( strcmp((char *)attr->name,"host") == 0 ) {
			common.dbserver = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.dbserver, (char *)attr->children->content );
		    }
		}
	    }

	    /* Save the AWIPS database table name */
	    if ( strcmp((char *)cur_node->name,"dbtable") == 0 ) {
		for (attr = cur_node->properties; attr; attr = attr->next) {
		    if ( strcmp((char *)attr->name,"name") == 0 ) {
			common.dbtable = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.dbtable, (char *)attr->children->content );
		    }
		}
	    }

	    /* Initialize the rows */
	    if ( strcmp((char *)cur_node->name,"rows") == 0 ) {
		common.numrows = 0;
		for (attr = cur_node->properties; attr; attr = attr->next) {
		    if ( strcmp((char *)attr->name,"pyfile") == 0 ) {
			common.pyfile_row = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.pyfile_row, (char *)attr->children->content );
		    }
		    if ( strcmp((char *)attr->name,"pymeth") == 0 ) {
			common.pymeth_row = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.pymeth_row, (char *)attr->children->content );
		    }
		    if ( strcmp((char *)attr->name,"dbkey") == 0 ) {
			common.dbkey_row = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.dbkey_row, (char *)attr->children->content );
		    }
		}
	    }
	    /* Save the row header information */
	    if ( strcmp((char *)cur_node->name,"row") == 0 ) {
		for (attr = cur_node->properties; attr; attr = attr->next) {
		    if ( strcmp((char *)attr->name,"name") == 0 ) {
			common.rows[common.numrows] = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.rows[common.numrows], (char *)attr->children->content );
			common.numrows++;
		    }
		}
	    }

	    /* Initialize the columns */
	    if ( strcmp((char *)cur_node->name,"columns") == 0 ) {
		common.numcols = 0;
		for (attr = cur_node->properties; attr; attr = attr->next) {
		    if ( strcmp((char *)attr->name,"pyfile") == 0 ) {
			common.pyfile_col = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.pyfile_col, (char *)attr->children->content );
		    }
		    if ( strcmp((char *)attr->name,"pymeth") == 0 ) {
			common.pymeth_col = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.pymeth_col, (char *)attr->children->content );
		    }
		    if ( strcmp((char *)attr->name,"dbkey") == 0 ) {
			common.dbkey_col = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.dbkey_col, (char *)attr->children->content );
		    }
		}
	    }
	    /* Save the column header information */
	    if ( strcmp((char *)cur_node->name,"column") == 0 ) {
		for (attr = cur_node->properties; attr; attr = attr->next) {
		    if ( strcmp((char *)attr->name,"name") == 0 ) {
			common.cols[common.numcols] = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.cols[common.numcols], (char *)attr->children->content );
			common.numcols++;
		    }
		}
	    }

	    /* Initialize the parts */
	    if ( strcmp((char *)cur_node->name,"parts") == 0 ) {
		common.numparts = 0;
	    }
	    /* Save the part header information */
	    if ( strcmp((char *)cur_node->name,"part") == 0 ) {
		for (attr = cur_node->properties; attr; attr = attr->next) {
		    if ( strcmp((char *)attr->name,"name") == 0 ) {
			common.parts[common.numparts].name = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.parts[common.numparts].name, (char *)attr->children->content );
			common.numparts++;
		    }
		    if ( strcmp((char *)attr->name,"type") == 0 ) {
			int nprt = common.numparts-1;
			FIND_KEY ( common.parts[nprt].type, ((char *)attr->children->content), dtype, Hash_t )
		    }
		    if ( strcmp((char *)attr->name,"pyfile") == 0 ) {
			int nprt = common.numparts-1;
			common.parts[nprt].pyfile = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.parts[nprt].pyfile, (char *)attr->children->content );
		    }
		    if ( strcmp((char *)attr->name,"pymethdata") == 0 ) {
			int nprt = common.numparts-1;
			common.parts[nprt].pymethdata = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.parts[nprt].pymethdata, (char *)attr->children->content );
		    }
		    if ( strcmp((char *)attr->name,"pymethhdr") == 0 ) {
			int nprt = common.numparts-1;
			common.parts[nprt].pymethhdr = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.parts[nprt].pymethhdr, (char *)attr->children->content );
		    }
		}
	    }

	    /* Initialize the parameters */
	    if ( strcmp((char *)cur_node->name,"parameters") == 0 ) {
		common.parts[common.numparts-1].numparms = 0;
	    }
	    /* Save the parameter information for this part */
	    if ( strcmp((char *)cur_node->name,"parameter") == 0 ) {
		for (attr = cur_node->properties; attr; attr = attr->next) {
		    if ( strcmp((char *)attr->name,"name") == 0 ) {
			int nprt = common.numparts-1;
			int nprm = common.parts[nprt].numparms;
			common.parts[nprt].parms[nprm].name = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.parts[nprt].parms[nprm].name, (char *)attr->children->content );
			common.parts[nprt].numparms++;
		    }
		    if ( strcmp((char *)attr->name,"scale") == 0 ) {
			int nprt = common.numparts-1;
			int nprm = common.parts[nprt].numparms-1;
			common.parts[nprt].parms[nprm].scale = atoi ((char *)attr->children->content ); 
		    }
		    if ( strcmp((char *)attr->name,"offset") == 0 ) {
			int nprt = common.numparts-1;
			int nprm = common.parts[nprt].numparms-1;
			common.parts[nprt].parms[nprm].offset = atoi ((char *)attr->children->content ); 
		    }
		    if ( strcmp((char *)attr->name,"bits") == 0 ) {
			int nprt = common.numparts-1;
			int nprm = common.parts[nprt].numparms-1;
			common.parts[nprt].parms[nprm].bits = atoi ((char *)attr->children->content ); 
		    }
		    if ( strcmp((char *)attr->name,"key") == 0 ) {
			int nprt = common.numparts-1;
			int nprm = common.parts[nprt].numparms-1;
			common.parts[nprt].parms[nprm].key = (char *)malloc(strlen((char *)attr->children->content));
			strcpy ( common.parts[nprt].parms[nprm].key, (char *)attr->children->content ); 
		    }
		}
	    }

	}

	/* Recursively process the children of the current node */
	process_elements(cur_node->children);
    }
}