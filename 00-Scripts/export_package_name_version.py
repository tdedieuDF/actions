import glob
from xml.dom.minidom import Element
from xml.etree import ElementTree
import argparse


def sortchildrenby(parent, attr):
    parent[:] = sorted(parent, key=lambda child: child.get(attr))


def exportAppList(tree: Element) -> list:

    treeComputers = listAttributes(tree, 'computer', 'name')
    appList = []
    for currentTreeComputer in treeComputers:
        # appComputer += [currentTreeComputer]
        treePackageNameVersion = listAttributesTuple(getAttrWithValue(
            tree, 'computer', 'name', currentTreeComputer), 'application', ('package_name', 'package_version'))
        sortchildrenby(treePackageNameVersion, 'package_name')
        for attr in treePackageNameVersion:
            appList += [attr['package_name'] + " " + attr['package_version']]

        # appComputer += list(dict.fromkeys(appList))
    appList = sorted(set(appList))
    return appList


def mergeComputers(tree1: Element, tree2: Element) -> Element:

    tree1Names = listAttributes(tree1, 'computer', 'name')
    tree2Names = listAttributes(tree2, 'computer', 'name')

    allAttr = set(tree1Names).union(set(tree2Names))

    for attr in allAttr:
        if attr in tree1Names and attr in tree2Names:
            print('Merging computer ' + attr)
            mergeApplications(
                getAttrWithValue(tree1, 'computer', 'name', attr),
                getAttrWithValue(tree2, 'computer', 'name', attr))
        elif attr in tree1Names:
            # nothing to do : we return tree1
            pass
        elif attr in tree2Names:
            tree1.append(getAttrWithValue(tree2, 'computer', 'name', attr))
        else:
            print('Weird error')

    sortchildrenby(tree1, 'name')
    return tree1


def mergeApplications(tree1: Element, tree2: Element) -> Element:

    tree1Names = listAttributesTuple(
        tree1, 'application', ('name', 'package_name'))
    tree2Names = listAttributesTuple(
        tree2, 'application', ('name', 'package_name'))

    allAttr = tree1Names + tree2Names

    for attr in allAttr:
        if attr in tree1Names and attr in tree2Names:
            print('Duplicated application')
        elif attr in tree1Names:
            # nothing to do : we return tree1
            pass
        elif attr in tree2Names:
            tree1.append(getAttrWithValueTuple(tree2, 'application', attr))
        else:
            print('Weird error')

    sortchildrenby(tree1, 'name')
    return tree1


def listAttributes(tree: Element, tagname: str, attrname: str) -> list:
    return [e.attrib[attrname] for e in tree if e.tag == tagname]


def listAttributesTuple(tree: Element, tagname: str, attrname: tuple) -> list:
    return [{attrname[0]: e.attrib[attrname[0]],
             attrname[1]: e.attrib[attrname[1]]}
            for e in tree if e.tag == tagname]


def getAttrWithValue(tree: Element, tagname: str, attrname: str, attrValue: str) -> list:
    return [e for e in tree if e.tag == tagname and e.attrib[attrname] == attrValue][0]


def getAttrWithValueTuple(tree: Element, tagname: str, attrib: dict) -> Element:
    elem_list = [e for e in tree
                 if e.tag == tagname
                 and not False in [e.attrib[k] == attrib[k] for k in attrib.keys()]]
    return elem_list[0]


def run(inputXMLFile: str, resultOutput: str):
    xml_files = glob.glob(inputXMLFile)
    print("my file: " + str(xml_files))

    allData = None

    for xml_file in xml_files:
        data = ElementTree.parse(xml_file).getroot()

        if allData is None:
            print('==> Initializing with ' + xml_file)
            allData = data
        else:
            print('==> Merging ' + xml_file)
            allData = mergeComputers(allData, data)

    appList = exportAppList(allData)
    with open(resultOutput, 'w+') as f:
        for content in appList:
            f.write(content + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input-xml-file",
                        required=True, help='input xml file')
    parser.add_argument("-o", "--output-file",
                        required=True, help='output file')

    args = parser.parse_args()
    run(args.input_xml_file, args.output_file)
